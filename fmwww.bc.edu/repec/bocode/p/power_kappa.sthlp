{smcl}
{* *! version 1.0.0 20Sept2023}{...}
{title:Title}

{p2colset 5 20 21 2}{...}
{p2col:{hi:power kappa} {hline 2}} Power analysis for the two-rater kappa statistic with two or more categories {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
Compute sample size

{p 8 43 2}
{opt power kappa} {it:kappa0} {it:kappa1}
{cmd:,} {opth marg(numlist)} [ {opth p:ower(numlist)} {opth a:lpha(numlist)} {opt onesid:ed} {opt gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}] ]

{phang}
Compute power 

{p 8 43 2}
{opt power kappa} {it:kappa0} {it:kappa1}
{cmd:,} {opth marg(numlist)} [ {opth n(numlist)} {opth a:lpha(numlist)} {opt onesid:ed} {opt gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}] ]


{phang}
where {it:kappa0} is the null (hypothesized) kappa and
{it:kappa1} is the alternative (target) kappa. {it:kappa0} and {it:kappa1} may each be 
specified either as one number or as a list of values in parentheses 
(see {help numlist}).{p_end}


{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt marg(numlist)}}marginal probabilities (frequencies) of assignment into each category. The category frequencies must sum to 1.0; {cmd:marg()} is required{p_end}
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
{opt power kappa} computes power and sample size for the kappa test of agreement between two raters when there are two or more categories
from which to choose from. {opt power kappa} computes power and sample size using the method described by Flack et al. (1988).



{title:Options}

{phang}
{opth marg(numlist)} {cmd: required}. The marginal probabilities of rating a subject (target) into {it:k} categories. The category frequencies must sum to 1.0. As an example,
Cohen (1968) uses psychiatric diagnosis agreement to illustrate measures of interrater agreement. There are three diagnostic categories: personality 
disorder (PD), neurosis (N), and psychosis (PS). The data have the two judges' estimated frequencies of rating subjects in each of the three categories 
as (0.50, 0.30, 0.20) and (0.60, 0.30, 0.10). While these marginal ratings frequencies are not identical to one another, they are similar enough to
justify the assumption that the true marginals are roughly the same for the two judges.

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
    Using the first row of data from Table 2 in Flack et al. (1988), we will compute the sample size required to detect a kappa of 0.60 given a
    kappa of 0.40 under the null hypothesis for 3 categories with marginal probabilities of 0.50 0.26 0.24. We specify a one-sided test,
	a 5% significance level and 80% power (the default).{p_end}
{phang2}{cmd:. power kappa 0.40 0.60, marg(0.50 0.26 0.24) alpha(0.05) onesided}

{pstd}
    Same as above, using a power of 90% and a two-sided test{p_end}
{phang2}{cmd:. power kappa 0.40 0.60, marg(0.50 0.26 0.24) alpha(0.05) power(0.90)}

{pstd}
    Same as above, but testing power at both 80% and 90% and alpha at the 0.01 and 0.05 level {p_end}
{phang2}{cmd:. power kappa 0.40 0.60, marg(0.50 0.26 0.24) alpha(0.01 0.05) power(0.80 0.90)}

{pstd}
    Same as above, but applying a range of kappa values under the alternative hypothesis
	and setting alpha levels to 0.05 and 0.01; and graphing the results {p_end}
{phang2}{cmd:. power kappa 0.40 (0.60(0.05).95), marg(0.50 0.26 0.24) power(0.80) alpha(0.01 0.05) graph}


    {title:Examples: Computing power}

{pstd}
    For a total sample of 93 subjects, compute the power of a one-sided test to 
    detect a kappa of 0.60 given a null kappa of 0.40 for 3 categories with marginal 
	probabilities of 0.50 0.26 0.24, at a 5% significance level (the default){p_end}
{phang2}{cmd:. power kappa 0.40 0.60, marg(0.50 0.26 0.24) n(93) onesided}

{pstd}
    Same as above but test alpha levels of 0.01, 0.05 and 0.10 {p_end}
{phang2}{cmd:. power kappa 0.40 0.60, marg(0.50 0.26 0.24) n(93) onesided alpha(0.01 0.05 0.10)}

{pstd}
	Compute powers for a range of sample sizes at alpha 0.01 and 0.05, 
	graphing the results{p_end}
{phang2}{cmd:. power kappa 0.40 0.60, marg(0.50 0.26 0.24) n(70(5)160) onesided alpha(0.01 0.05) graph}	



{title:Stored results}

{pstd}
{cmd:power kappa} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd: r(alpha)}}significance level{p_end}
{synopt:{cmd: r(kappa0)}}null kappa{p_end}
{synopt:{cmd: r(kappa1)}}alternative kappa{p_end}
{synopt:{cmd: r(tau0)}}max std error for the null kappa{p_end}
{synopt:{cmd: r(tau1)}}max std error for the alternative kappa{p_end}
{synopt:{cmd: r(beta)}}probability of a type II error{p_end}
{synopt:{cmd: r(delta)}}effect size{p_end}
{synopt:{cmd: r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}
{synopt:{cmd: r(N)}}total sample size{p_end}
{synopt:{cmd: r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}
{synopt:{cmd: r(power)}}power{p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}{cmd:kappa}{p_end}
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
Cohen, J. 1968. Weighted kappa: Nominal scale agreement with provision for scaled disagreement or partial
credit. {it:Psychological Bulletin} 70: 213-220. {p_end}

{p 4 8 2} 
Flack, V. F., Afifi, A. A., Lachenbruch, P. A., and H. J. A. Schouten. 1988. Sample size determinations for the two
rater kappa statistic. {it:Psychometrika} 53: 321-325. {p_end}



{marker citation}{title:Citation of {cmd:power kappa}}

{p 4 8 2}{cmd:power kappa} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). POWER KAPPA: Stata module to compute power and sample size for the two-rater kappa statistic with two or more categories



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb kappa}, {helpb power}, {helpb kapssi} (if installed), {helpb sskdlg} (if installed){p_end}

