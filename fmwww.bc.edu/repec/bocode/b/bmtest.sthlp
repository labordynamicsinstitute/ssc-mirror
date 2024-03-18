{smcl}
{* *! version 1.0.0  15mar2024}{...}

{title:Title}

{p2colset 5 15 16 2}{...}
{p2col:{hi:bmtest} {hline 2}} Two-sample Brunner-Munzel test  {p_end}
{p2colreset}{...}



{marker syntax}{...}
{title:Syntax}

{p 8 19 2}
		{cmd:bmtest} {varname} {ifin} {cmd:,} {cmd:by(}{it:{help varname:groupvar}}{cmd:)} 
		[ {opt dir:ection}({it:string})
		{opt rev:erse}		
		{opt lev:el(#)} ]



{synoptset 19 tabbed}{...}
{synoptline}
{p2coldent:* {opt by:(groupvar)}}grouping variable {p_end}
{synopt:{opt dir:ection(string)}}directional hypothesis. "lt" indicates that the first level of {opt by()} should be tested as being "less-than" the second level, "gt" 
indicates that the first level of {opt by()} should be tested as being "greater-than" the second level, or "" (or not specifying {opt direction()} at all) 
indicates a two-sided hypothesis{p_end}
{synopt:{opt rev:erse}}reverse group order for the {opt bmtest} computation{p_end}
{synopt:{opt lev:el(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:bmtest} implements the Brunner–Munzel test for two independent samples (Brunner & Munzel 2000; Neubert & Brunner 2007; Karch 2023) featuring fewer assumptions than the Wilcoxon–Mann–Whitney test (Karch 2023).

{pstd}
The Brunner–Munzel (BM) test produces a {it:relative effect} estimate of group affiliation on the outcome. In words, the relative effect {it:p} represents the 
probability that a randomly selected individual from the second group will have a larger outcome than a randomly selected individual from the first group (Karch 2023).

{pstd}
The {it:relative effect} is computed as {it:p} = P(X1 < X2) + 0.5P(X1 = X2), where the probability of a tie is assigned with equal weight = 0.5 to both possibilities
(X1 smaller, and X2 smaller). If the relative effect is {it:p} = 0.5, groups 1 and 2 are deemed (stochastically) comparable, which is the null hypothesis of the BM 
test. For two-sided testing, the alternative hypothesis is that HA : {it:p} ≠ 0.5, indicating that the groups are not comparable. For one-sided testing, the alternative 
hypothesis can be either HA : {it:p} > 0.5, indicating that X1 tends to take smaller values, or HA : {it:p} < 0.5, indicating that X1 tends to take greater values (Karch 2023).

{pstd}
See Karch (2023) for a comprehensive, yet accessible, discsussion of the BM test.



{title:Options}

{phang}
{cmd:by(}{it:{help varlist:groupvar}}{cmd:)} is required. It specifies the name of the grouping variable.

{phang}
{cmd:direction(}{it:string}{cmd:)} specifies a directional hypothesis. {opt direction("lt")} indicates that the first level of {opt by()} should be tested 
as being "less-than" the second level, {opt direction("gt")} indicates that the first level of {opt by()} should be tested as being "greater-than" the 
second level, or "" (or not specifying {opt direction()} at all) indicates a two-sided hypothesis.

{phang}
{cmd:reverse} reverses the order of the groups defined in by(). For example, if X1 is initially ordered lower than X2, then the relative effect estimate will 
correspond to {it:p} = P(X1 < X2) + 0.5P(X1 = X2). Conversely, when {cmd:reverse} is specified, X2 will be ordered lower than X1, providing a relative
effect estimate corresponding to {it:p} = P(X2 < X1) + 0.5P(X2 = X1). 

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence intervals. The default is {cmd:level(95)} or as set by {helpb set level}.



{title:Examples}

{pstd}Load example data{p_end}
{p 4 8 2}{stata "webuse fuel2, clear":. webuse fuel2, clear}{p_end}

{pstd}Perform standard BM test{p_end}
{p 4 8 2}{stata "bmtest mpg, by(treat)":. bmtest mpg, by(treat)}{p_end}

{pstd}Reverse order of the grouping variable {opt treat}{p_end}
{p 4 8 2}{stata "bmtest mpg, by(treat) reverse":. bmtest mpg, by(treat) reverse}{p_end}

{pstd}Set CI level to 99%{p_end}
{p 4 8 2}{stata "bmtest mpg, by(treat) level(99)":. bmtest mpg, by(treat) level(99)}{p_end}

{pstd}Specify directional hypothesis that group 1 is < group 2 {p_end}
{p 4 8 2}{stata "bmtest mpg, by(treat) dir(lt)":. bmtest mpg, by(treat) dir(lt)}{p_end}

{pstd}Specify directional hypothesis that group 1 is > group 2 {p_end}
{p 4 8 2}{stata "bmtest mpg, by(treat) dir(gt)":. bmtest mpg, by(treat) dir(gt)}{p_end}



{title:Saved results}

{pstd}{cmd:bmtest} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(coef)}}relative effect estimate {p_end}
{synopt:{cmd:r(df)}}BM degrees of freedom {p_end}
{synopt:{cmd:r(t)}}BM t statistic {p_end}
{synopt:{cmd:r(p)}}{it:p}-value{p_end}
{synopt:{cmd:r(ul)}}upper confidence limit{p_end}
{synopt:{cmd:r(ll)}}lower confidence limit{p_end}
{synopt:{cmd:r(n1)}}sample size of group 1{p_end}
{synopt:{cmd:r(n2)}}sample size of group 2{p_end}


{p2colreset}{...}

{title:References}

{phang}
Brunner, E. and U. Munzel. 2000. The Nonparametric Behrens-Fisher Problem: Asymptotic Theory and a Small-Sample Approximation.{it:Biometrical Journal} 42: 17–25.

{phang}
Karch, J. D. 2023. bmtest: A Jamovi module for Brunner–Munzel's test — A robust alternative to Wilcoxon–Mann–Whitney's test. {it:Psych} 5: 386-395.

{phang}
Neubert, K. and E Brunner. 2007. A Studentized permutation test for the non-parametric Behrens-Fisher problem. {it:Computational Statistics and Data Analysis} 51: 5192–5204.
 


{title:Citation of {cmd:bmtest}}

{p 4 8 2}{cmd:bmtest} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2024. bmtest: Stata module for computing the independent two-sample Brunner-Munzel test.
{p_end}



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}


        
{title:Also see}

{p 4 8 2}Online: {helpb ranksum}{p_end}
