{smcl}
{* *! version 1.0.1  08jan2026}{...}

{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{hi:wasstest} {hline 2}}Two-sample Wasserstein Distance test for equality of distributions {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:wasstest}
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
{synopt :{opt p:ower(#)}}specify the exponent for the Wasserstein statistic; default is {opt power(1)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt Required}


{title:Description}

{pstd}
{cmd:wasstest} performs a two-sample Wasserstein distance permutation test 
to assess whether two samples come from the same distribution. The 
Wasserstein distance (also known as Earth Mover's Distance) measures 
the minimum "work" required to transform one distribution into another.
Unlike Cramer-von Mises and Anderson-Darling tests which focus on 
vertical differences between CDFs, the Wasserstein distance considers 
both vertical differences and the horizontal distances between points, 
making it sensitive to both location and spread differences. The permutation 
test provides an exact p-value by comparing the observed statistic to its 
distribution under random reassignment of group labels.



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
{opt p:ower(#)} specifies the exponent for the Wasserstein statistic calculation; 
the default is power(1) which gives the standard Wasserstein distance (Earth Mover's 
Distance), measuring the minimum "work" to transform one distribution into another.
{opt power(>1)} gives more weight to large vertical discrepancies between distributions.
{opt power(<1)} gives more balanced weighting, reducing the relative importance of large discrepancies.		
			


{title:Examples}

{pstd}Set-up{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 20}{p_end}
{phang2}{cmd:. gen group = cond(_n < 11,1,2)}{p_end}
{phang2}{cmd:. gen x = runiform() in 1/10}{p_end}
{phang2}{cmd:. replace x = runiform() * 1.30 if group==2}{p_end}

{pstd}{opt wasstest} using defaults{p_end}
{phang2}{cmd:. wasstest x, by(group)}

{pstd}{opt wasstest} with specific seed and more permutations{p_end}
{phang2}{cmd:. wasstest x, by(group) reps(2000) seed(12345)}{p_end}

{pstd}change exponent to cubed weighting{p_end}
{phang2}{cmd:. wasstest x, by(group) reps(2000) seed(12345) power(3)}{p_end}



{title:Stored results}

{pstd}
{cmd:wasstest} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 14 16 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}observed Wasserstein statistic{p_end}
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
Villani, C. 2009.
{it:Optimal Transport: Old and New}.
Springer.

{phang}    
Ramdas, A., Garcia, N., and Cuturi, M. 2017.
On Wasserstein two-sample testing and related families of nonparametric tests.
{it:Entropy}
19: 47.



{title:Citation of {cmd:wasstest}}

{p 4 8 2}{cmd:wasstest} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). WASSTEST: Stata module to perform a two-sample Wasserstein Distance test for equality of distributions. Statistical Software Components S459557, Boston College Department of Economics. 



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} {helpb ksmirnov}, {helpb ranksum}, {helpb permute}, {helpb cvmtest} (if installed), {helpb adtest} (if installed), {helpb kuipertest} (if installed), {helpb escftest} (if installed), {helpb distcomp} (if installed) {p_end}



