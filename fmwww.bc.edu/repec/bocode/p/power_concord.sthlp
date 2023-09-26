{smcl}
{* *! version 1.0.0 22Sept2023}{...}
{title:Title}

{p2colset 5 22 23 2}{...}
{p2col:{hi:power concord} {hline 2}} Power analysis for Lin's concordance correlation coefficient {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
Compute sample size

{p 8 43 2}
{opt power concord} {it:concord0} {it:concord1}
{cmd:,} [ {opth p:ower(numlist)} {opth a:lpha(numlist)} {opt onesid:ed} {opt gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}] ]

{phang}
Compute power 

{p 8 43 2}
{opt power concord} {it:concord0} {it:concord1}
{cmd:,} [ {opth n(numlist)} {opth a:lpha(numlist)} {opt onesid:ed} {opt gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}] ]


{phang}
where {it:concord0} is the null (hypothesized) concordance coefficient and
{it:concord1} is the alternative (target) concordance coefficient. {it:concord0} and {it:concord1} may each be 
specified either as one number or as a list of values in parentheses 
(see {help numlist}).{p_end}


{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth a:lpha(numlist)}}significance level; default is {cmd:alpha(0.05)} {p_end}
{p2coldent:* {opth p:ower(numlist)}}power; default is {cmd:power(0.80)} {p_end}
{p2coldent:* {opth n(numlist)}}total sample size; required to compute power {p_end}
{synopt :{opt onesid:ed}}one-sided test; default is two sided{p_end}
{synopt :{cmdab:gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}]}graph results; see {manhelp power_optgraph PSS-2:power, graph}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* Specifying a list of values in at least two starred options, or 
two command arguments, or at least one starred option and one argument
results in computations for all possible combinations of the values; see
{help numlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt power concord} computes power and sample size for Lin's concordance coefficient using the "simplifed method" described in Lin et al. (2012).
For the case of two raters with a single reading per rater, the computations of the power and sample size are simplified by using the upper 
bound of the variance of each estimate of the agreement indices (see page 72 of Lin et al. [2012] for details).



{title:Options}

{phang}
{opth a:lpha(numlist)} sets the significance level of the test. The
default is {cmd:alpha(0.05)}.

{phang} 
{opth p:ower(numlist)} specifies the desired power at which sample size is to be computed. 
If {cmd:power()} is specified in conjunction with {cmd:n()}, 
then the actual power of the test is presented.

{phang} 
{opth n(numlist)} specifies the total number of subjects in the study to be used for determining power. 

{phang} 
{opt onesid:ed} indicates a one-sided test. The default is two sided. 

{phang}
{opt gr:aph}, {cmd:graph()}; see {manhelp power_optgraph PSS-2: power, graph}.



{title:Examples}

    {title:Examples: Computing sample size}

{pstd}
    We want to use Lin's concordance correlation coefficient to compare a new measurement method to the "gold standard" method
	to determine whether the new method can replace the gold standard method. We assume that the concordance coefficient 
	is 0.95 under the null hypothesis and 0.97 under the alternative hypothesis. We specify a one-sided test, a 5% significance level 
	and 80% power (the defaults).{p_end}
{phang2}{cmd:. power concord 0.95 0.97, onesided}

{pstd}
    Same as above, using a power of 90%, an alpha of 1% and a two-sided test{p_end}
{phang2}{cmd:. power concord 0.95 0.97, power(0.90) alpha(0.01)}

{pstd}
    Same as above, but testing power at both 80% and 90% and alpha at the 1% and 5% level {p_end}
{phang2}{cmd:. power concord 0.95 0.97, alpha(0.01 0.05) power(0.80 0.90)}

{pstd}
    Same as above, but applying a range of concordance coefficient values under the alternative hypothesis
	and setting alpha levels to 1% and 5%; and graphing the results {p_end}
{phang2}{cmd:. power concord 0.95 0.96(0.01)0.99, power(0.80) alpha(0.01 0.05) graph}


    {title:Examples: Computing power}

{pstd}
    For a total sample of 94 subjects, compute the power of a one-sided test to 
    detect a concordance of 0.97 given a null concordance of 0.95
	at a 5% significance level (the default){p_end}
{phang2}{cmd:. power concord 0.95 0.97, onesided n(94)}

{pstd}
    Same as above but test alpha levels of 1%, 5% and 10% {p_end}
{phang2}{cmd:. power concord 0.95 0.97, onesided n(94) alpha(0.01 0.05 0.10)}

{pstd}
	Compute powers for a range of sample sizes at alpha 1% and 5%, 
	graphing the results{p_end}
{phang2}{cmd:. power concord 0.95 0.97, onesided n(70(5)160) alpha(0.01 0.05) graph}	



{title:Stored results}

{pstd}
{cmd:power concord} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd: r(alpha)}}significance level{p_end}
{synopt:{cmd: r(concord0)}}null concordance coefficient{p_end}
{synopt:{cmd: r(concord1)}}alternative concordance coefficient{p_end}
{synopt:{cmd: r(beta)}}probability of a type II error{p_end}
{synopt:{cmd: r(delta)}}effect size{p_end}
{synopt:{cmd: r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}
{synopt:{cmd: r(N)}}total sample size{p_end}
{synopt:{cmd: r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}
{synopt:{cmd: r(power)}}power{p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}{cmd:concord}{p_end}
{synopt:{cmd:r(columns)}}displayed table columns{p_end}
{synopt:{cmd:r(labels)}}table column labels{p_end}
{synopt:{cmd:r(widths)}}table column widths{p_end}
{synopt:{cmd:r(formats)}}table column formats{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(pss_table)}}table of results{p_end}
{p2colreset}{...}


{title:References}

{p 4 8 2} 
Lin, L., Hedayat, A. S., and W. Wu. 2012. {it:Statistical Tools for Measuring Agreement}. Springer, New York. {p_end}



{marker citation}{title:Citation of {cmd:power concord}}

{p 4 8 2}{cmd:power concord} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A., and L. Lin. 2023. POWER CONCORD: Stata module to compute power and sample size for Lin's concordance correlation coefficient



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}

{p 4 4 2}
Lawrence Lin{break}
equeilin@gmail.com{break}



{title:Also see}

{p 4 8 2} Online: {helpb power}, {helpb concord} (if installed){p_end}

