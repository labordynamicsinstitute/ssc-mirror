{smcl}
{* *! version 1.0.0 30jan2024}{...}
{title:Title}

{p 4 4 2}
{opt tau2ci} - Compute standard error and confidence interval for the tau-squared statistic in random-effects meta-analysis
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tau2ci}
[{cmd:,} {opt l:evel(#)}]

{pstd}
{helpb meta regress} with a random-effects method must be estimated prior to running {opt tau2ci}


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:tau2ci} is a post-estimation command that computes the standard error and
confidence interval for the between-study variance component tau-squared statistic
after fitting a random-effects meta-regression model using {helpb meta regress} 
with the {cmd:random()} option. It supports all random-effects estimation methods 
currently available in Stata's meta suite. {cmd:tau2ci} uses the  
standard error formulas implemented in the {browse "https://www.metafor-project.org/doku.php/metafor":metafor} 
package in R.



{title:Options}

{phang}
{opt level(#)}; see {helpb estimation options##level():[R] Estimation options}.



{title:Examples}

{pstd}Random-effects meta-regression with only the constant (same as running {helpb meta summary}){p_end}
{phang2}{cmd:. webuse bcgset, clear}{p_end}
{phang2}{cmd:. meta esize npost nnegt nposc nnegc, esize(lnrratio) studylabel(studylbl)}{p_end}
{phang2}{cmd:. meta regress _cons, random(reml)}{p_end}
{phang2}{cmd:. tau2ci}{p_end}

{pstd}meta regress with moderators{p_end}
{phang2}{cmd:. meta regress latitude year, random(reml)}{p_end}
{phang2}{cmd:. tau2ci}{p_end}


{title:Stored results}

{pstd}
{cmd:tau2ci} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(tau2)}}estimated tau-squared statistic{p_end}
{synopt:{cmd:r(se)}}standard error of the tau-squared statistic{p_end}
{synopt:{cmd:r(ll)}}lower confidence limit for the tau-squared statistic{p_end}
{synopt:{cmd:r(ul)}}upper confidence limit for the tau-squared statistic{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(method)}}random-effects estimation method used{p_end}
{p2colreset}{...}



{title:References}

{phang}
Viechtbauer, W. 2005. Bias and efficiency of meta-analytic variance estimators
in the random-effects model.
{it:Journal of Educational and Behavioral Statistics} 30: 261–293.

{phang}
Viechtbauer, W. 2010. Conducting meta-analyses in R with the metafor package.
{it:Journal of Statistical Software} 36(3): 1–48.



{title:Citation of {cmd:tau2ci}}

{p 4 8 2}{cmd:tau2ci} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2026). TAU2CI: Stata module to compute standard error and confidence interval for the tau-squared statistic in random-effects meta-analysis



{title:Author}

{p 4 4 2}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also See}

{p 4 4 2}
{helpb meta regress} {p_end}


