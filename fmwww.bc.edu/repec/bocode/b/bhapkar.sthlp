{smcl}
{* *! version 1.0.0 31July2023}{...}
{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{hi:bhapkar} {hline 2}} Bhapkar's test of marginal homogeneity between two raters for categorical observations {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:bhapkar}
{it:{help varname:rater1}} 
{it:{help varname:rater2}} 
{ifin}


{p2colreset}{...}
{p 4 6 2}
{opt by} is allowed with {cmd:bhapkar}; see {manhelp by D}.{p_end}



{marker description}{...}
{title:Description}

{pstd}
{opt bhapkar} computes Bhapkar's chi-squared statistic to assess the marginal homogeneity (agreement) between two raters on categorical data 
(Bhapkar 1966). If the associated p-value is significant (e.g. < 0.05), the hypothesis of equal marginal distributions is rejected. 
That is, we do not accept the assumption that there is agreement between the two raters. Conversely, a non-significant
p-value can be interpreted as the two raters having equal marginal distributions (i.e. there is interrater agreement).



{title:Examples}

{pstd}Setup for categorical level data{p_end}
{phang2}{cmd:. vision.dta}{p_end}

{pstd}These data are ratings of unaided distance vision between left and right eye of 7477 female employees in Royal Ordnance factories between 1943 and 1946.{p_end}
{phang2}{cmd:. bhapkar reye leye}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:bhapkar} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(chisq)}}the chi-squared statistic{p_end}
{synopt:{cmd:r(pval)}}the p-value of the chi-squared statistic (subjects){p_end}
{synopt:{cmd:r(nrat)}}the number of unique raters{p_end}
{synopt:{cmd:r(ntar)}}the number of targets (observations){p_end}
{synopt:{cmd:r(df)}}the degrees of freedom{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Bhapkar, V.P. 1966. A note on the equivalence of two test criteria for hypotheses in categorical data. 
{it:Journal of the American Statistical Association} 61: 228-235.{p_end}



{marker citation}{title:Citation of {cmd:iota}}

{p 4 8 2}{cmd:bhapkar} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). BHAPKAR: Stata module to compute Bhapkar's test of marginal homogeneity between two raters for categorical observations.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb symmetry}, {helpb kappaetc} (if installed), {helpb finn} (if installed), {helpb iota} (if installed), {helpb maxwell} (if installed){p_end}

