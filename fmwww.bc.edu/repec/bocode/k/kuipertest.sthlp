{smcl}
{* *! version 1.0.0  23dec2025}{...}

{title:Title}

{p2colset 5 19 20 2}{...}
{p2col:{hi:kuipertest} {hline 2}}Two-sample Kuiper test for equality of distributions {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:kuipertest}
{varname} {ifin} {cmd:,} {opth "by(varlist:groupvar)"}
[{cmd:,} 
{opt r:eps(#)}
{opt seed(#)} 
{opt p:ower(#)}]

{pstd}
{it:{help varlist:groupvar}} must take on
two distinct values. The distribution of {it:varname} for the first value of
{it:groupvar} is compared with that of the second value.



{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth "by(varlist:groupvar)"}}specify a binary variable that identifies the two groups{p_end}
{synopt :{opt r:eps(#)}}perform # Monte Carlo permutations; default is {opt reps(1000)}{p_end}
{synopt :{opt seed(#)}}set random-number seed to #{p_end}
{synopt :{opt p:ower(#)}}specify the exponent for the Kuiper statistic; default is {opt power(1)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt Required}


{title:Description}

{pstd}
{cmd:kuipertest} performs a two-sample Kuiper permutation test to assess 
whether two samples come from the same distribution. The Kuiper statistic measures 
the maximum positive and negative deviations between empirical cumulative distribution 
functions (ECDFs). The permutation test provides an exact p-value by comparing the 
observed statistic to its distribution under random reassignment of group labels.



{title:Options}

{p 6 8 2}
{opth "by(varlist:groupvar)"} is required. It specifies a binary variable
that identifies the two groups.

{p 6 8 2}
{opt r:eps(#)} specifies the number of random permutations for the test; 
the default is {opt reps(1000)}.

{p 6 8 2}    
{opt seed(#)} sets the random-number seed for reproducible results. 

{p 6 8 2}    
{opt p:ower(#)} specifies the exponent for the Kuiper statistic calculation; 
the default is power(1) gives the standard Kuiper statistic.{opt power(>1)}
gives more weight to extreme deviations.



{title:Examples}

{pstd}Set-up{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 20}{p_end}
{phang2}{cmd:. gen group = cond(_n < 11,1,2)}{p_end}
{phang2}{cmd:. gen x = runiform() in 1/10}{p_end}
{phang2}{cmd:. replace x = runiform() * 1.30 if group==2}{p_end}

{pstd}{opt kuipertest} using defaults{p_end}
{phang2}{cmd:. kuipertest x, by(group)}

{pstd}{opt kuipertest} with specific seed and more permutations{p_end}
{phang2}{cmd:. kuipertest x, by(group) reps(2000) seed(12345)}{p_end}

{pstd}change power to squared weighting{p_end}
{phang2}{cmd:. kuipertest x, by(group) reps(2000) seed(12345) power(2)}{p_end}



{title:Stored results}

{pstd}
{cmd:kuipertest} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 14 16 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}observed Kuiper statistic{p_end}
{synopt:{cmd:r(p)}}permutation p-value{p_end}
{synopt:{cmd:r(reps)}}number of permutations performed{p_end}
{synopt:{cmd:r(power)}}power parameter specified{p_end}
{p2colreset}{...}

{synoptset 12 tabbed}{...}
{p2col 5 14 16 2: Macros}{p_end}
{synopt:{cmd:r(group1)}}name of group 1{p_end}
{synopt:{cmd:r(group2)}}name of group 2{p_end}
{p2colreset}{...}



{title:References}

{phang}
Kuiper, N. H. 1960.
Tests concerning random points on a circle.
{it:Proceedings of the Koninklijke Nederlandse Akademie van Wetenschappen, Series A}.
63: 38-47.

{phang}    
Stephens, M. A. 1970.
Use of the Kolmogorov-Smirnov, Cramer-von Mises and related statistics without extensive tables.
{it:Journal of the Royal Statistical Society, Series B}.
32: 115-122.



{title:Citation of {cmd:wasstest}}

{p 4 8 2}{cmd:kuipertest} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). KUIPERTEST: Stata module to perform a two-sample Kuiper test for equality of distributions



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} {helpb ksmirnov}, {helpb ranksum}, {helpb permute}, {helpb cvmtest} (if installed), {helpb adtest} (if installed), {helpb wasstest} (if installed), {helpb escftest} (if installed), {helpb distcomp} (if installed) {p_end}



