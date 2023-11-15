{smcl}
{* *! version 1.0.0 08Nov2023}{...}
{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{hi:centile2} {hline 2}} Enhancement to Stata's official centile command that provides additional definitions for computing sample quantiles {p_end}
{p2colreset}{...}



{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:centile2} [{varlist}] {ifin}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opth c:entile(numlist)}}report specified centiles;
default is {cmd:centile(50)}{p_end}

{syntab:Options}
{synopt :{opt t:ype(#)}}an integer between 4 and 9 selecting one of six continuous quantile algorithms; default is {cmd:type(6)}{p_end}
{synopt :{opt cc:i}}binomial exact; conservative confidence interval{p_end}
{synopt :{opt n:ormal}}normal, based on observed centiles{p_end}
{synopt :{opt m:eansd}}normal, based on mean and standard deviation{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{opt by}, {opt collect}, and {opt statsby} are allowed; see {help prefix}.



{marker description}{...}
{title:Description}

{pstd}
{cmd:centile2} is an enhancement to Stata's official {helpb centile} command that allows the user to select amongst six algorithms 
for defining the quantile (centile), corresponding to the continuous sample quantile types described in Hyndman and Fan (1996),
and likewise implemented in R's {browse "https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/quantile":quantile} function.
The availability of different definitions for computing sample quantiles ensures that the same result can be reproduced using different software
packages.

{pstd}
{cmd:centile2} estimates specified centiles and calculates confidence intervals. If no {varlist} is specified,
{cmd:centile2} calculates centiles for all the variables in the dataset. If no centiles are specified, medians are reported.

{pstd}
By default, {cmd:centile2} uses a binomial method for obtaining confidence intervals that makes no assumptions about the underlying 
distribution of the variable.



{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opth centile(numlist)} specifies the centiles to be reported.
The default is to display the 50th centile.
Specifying
{cmd:centile(5)} requests that the fifth centile be reported.
Specifying {cmd:centile(5 50 95)} requests that the 5th, 50th, and 95th
centiles be reported.
Specifying {cmd:centile(10(10)90)} requests that the 10th, 20th, ..., 90th
centiles be reported.

{dlgtab:Options}

{phang}
{opt type(#)} specifies which of the six algorithms should be used to compute
the centile. {opt type(4)} is a linear interpolation of the empirical cdf; 
{opt type(5)} is a piecewise linear function where the knots are the values 
midway through the steps of the empirical cdf; {opt type(6)} is used by {help centile}
in Stata, as well as by Minitab and SPSS; {opt type(7)} is the default used in R's 
{browse "https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/quantile":quantile}
function; {opt type(8)} produces quantile estimates that are approximately median-unbiased 
regardless of the distribution of {varlist}; and {opt type(9)} produces quantile estimates 
that are approximately unbiased for the expected order statistics if {varlist} is normally distributed.
{opt The default is type(6)} and will return the same results as {helpb centile}. 
Hyndman and Fan (1996) recommend using {opt type(8)}. 

{phang}
{opt cci} (conservative confidence interval) forces the confidence limits to
fall exactly on sample values.  Confidence intervals displayed with the
{opt cci} option are slightly wider than those with the default ({opt nocci})
option.

{phang}
{opt normal} causes the confidence interval to be calculated by using a formula
for the standard error of a normal-distribution quantile given by
Kendall and Stuart (1969, 237). The {opt normal} option
is useful when you want empirical centiles -- that is, centiles based on sample
order statistics rather than on the mean and standard deviation -- and are
willing to assume normality.

{phang}
{opt meansd} causes the centile and confidence interval to be calculated based
on the sample mean and standard deviation, and it assumes normality.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for
confidence intervals.  The default is {cmd:level(95)} or as set by
{helpb set level}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto}{p_end}

{pstd}Calculate the 50th centile for all variables in the dataset using the default definition {opt type(6)}{p_end}
{phang2}{cmd:. centile2}{p_end}

{pstd}Calculate the 25th, 50th, and 75th centiles for {cmd:price} using {opt type(7)} -- the default definition used in R's
{browse "https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/quantile":quantile} function {p_end}
{phang2}{cmd:. centile2 price, centile(25 50 75) type(7)}{p_end}

{pstd}Same as above but showing 99% CI{p_end}
{phang2}{cmd:. centile2 price, centile(25 50 75) type(7) level(99)}{p_end}

{pstd}Same as above but assuming normality{p_end}
{phang2}{cmd:. centile2 price, centile(25 50 75) type(7) level(99) normal}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:centile2} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(type)}}definition {it:#} used for computing centile{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(n_cent)}}number of centiles requested{p_end}
{synopt:{cmd:r(c_}{it:#}{cmd:)}}value of {it:#} centile{p_end}
{synopt:{cmd:r(lb_}{it:#}{cmd:)}}{it:#}-requested centile lower confidence
	bound{p_end}
{synopt:{cmd:r(ub_}{it:#}{cmd:)}}{it:#}-requested centile upper confidence
	bound{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(centiles)}}centiles requested{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Hyndman, R. J. and Y. Fan. 1996.
Sample quantiles in statistical packages. {it:American Statistician} 50: 361-365.
{p_end}

{phang}
Kendall, M. G., and A. Stuart. 1969.
{it:The Advanced Theory of Statistics, Vol. 1: Distribution Theory}. 3rd ed.
London: Griffin.
{p_end}



{marker citation}{title:Citation of {cmd:centile2}}

{p 4 8 2}{cmd:centile2} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2023). CENTILE2: Enhancement to Stata's official centile command that provides additional definitions for computing sample quantiles {p_end}


{title:Author}

{p 4 8 2}       Ariel Linden{p_end}
{p 4 8 2}       President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}{browse "mailto:alinden@lindenconsulting.org":alinden@lindenconsulting.org}{p_end}
{p 4 8 2}{browse "http://www.lindenconsulting.org"}{p_end}

         

{title:Also see}

{p 4 8 2} Online: {helpb centile}, {helpb summarize}{p_end}

