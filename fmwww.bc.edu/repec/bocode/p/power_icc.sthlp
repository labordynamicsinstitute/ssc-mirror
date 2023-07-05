{smcl}
{* *! version 1.0.0 03July2023}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col:{hi:power icc} {hline 2}} Power analysis for one-way random-effects intraclass correlation  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
Compute sample size

{p 8 43 2}
{opt power icc} {it:icc0} {it:icc1}
[{cmd:,} {opth p:ower(numlist)} {opth a:lpha(numlist)} {opth nr(numlist)} {opt onesid:ed} {opt gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}] ]

{phang}
Compute power 

{p 8 43 2}
{opt power icc} {it:icc0} {it:icc1}
[{cmd:,} {opth n(numlist)} {opth a:lpha(numlist)} {opth nr(numlist)} {opt onesid:ed} {opt gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}] ]


{phang}
where {it:icc0} is the null (hypothesized) intraclass correlation (ICC) and
{it:icc1} is the alternative (target) ICC. {it:icc0} and {it:icc1} may each be 
specified either as one number or as a list of values in parentheses 
(see {help numlist}).{p_end}


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth a:lpha(numlist)}}significance level; default is {cmd:alpha(0.05)} {p_end}
{p2coldent:* {opth p:ower(numlist)}}power; default is {cmd:power(0.80)} {p_end}
{p2coldent:* {opth n(numlist)}}total sample size; required to compute power {p_end}
{p2coldent:* {opth nr(numlist)}}number of raters/ratings; default is {cmd:nr(2)} {p_end}
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
{opt power icc} computes sample size or power for a one-way random-effects intraclass correlation, according to Equation 7 of Zou (2012), which is equivalent
to that given by Walter et al. (1998) who derived the formulas from a hypothesis testing perspective. 

{pstd}
{opt power icc} is useful for computing power/sample size under three diffferent scenarios; (1) when "n" subjects are each rated by the same "k" raters 
(inter-rater reliability), (2) a single subject is assessed repeatedly on each of several occasions (test-retest reliability), or (3) when replicates consisting
of different occasions are taken on different subjects by a single rater (Shoukri et al 2004).
 


{title:Options}

{phang}
{opth a:lpha(numlist)} sets the significance level of the test.  The
default is {cmd:alpha(0.05)}.

{phang} 
{opth p:ower(numlist)} specifies the desired power at which sample size is to be computed. 
If {cmd:power()} is specified in conjunction with {cmd:n()}, 
then the actual power of the test is presented.

{phang} 
{opth n(numlist)} specifies the total number of subjects in the study to be used for determining power. 

{phang}
{opth nr(numlist)} specifies the number of ratings or raters. The default is {cmd:nr(2)}.

{phang} 
{opt onesid:ed} indicates a one-sided test. The default is two sided. 

{phang}
{opt gr:aph}, {cmd:graph()}; see {manhelp power_optgraph PSS-2: power, graph}.



{title:Examples}

    {title:Examples: Computing sample size}

{pstd}
    Compute the sample size required to detect an ICC of 0.90 given an
    ICC of 0.50 under the null hypothesis using a two-sided test and assuming
	2 ratings per subject, a 5% significance level and 80% power (the defaults) {p_end}
{phang2}{cmd:. power icc 0.50 0.90}

{pstd}
    Same as above, using a power of 90% and a one-sided test{p_end}
{phang2}{cmd:. power icc 0.50 0.90, power(0.90) onesided}

{pstd}
    Same as above, but testing power at both 80% and 90% and alpha at the 0.01 and 0.05 level {p_end}
{phang2}{cmd:. power icc 0.50 0.90, alpha(0.01 0.05) power(0.80 0.90) onesided}

{pstd}
    Same as above, but applying a range of ICC values under the alternative hypothesis
	and setting alpha levels to 0.05 and 0.01; and graphing the results {p_end}
{phang2}{cmd:. power icc 0.50 (0.60(0.05).95), power(0.90) onesided alpha(0.01 0.05) graph}


    {title:Examples: Computing power}

{pstd}
    For a total sample of 60 subjects, compute the power of a two-sided test to 
    detect an ICC of 0.90 given a null ICC of 0.80 assuming 2 ratings per subject
	at a 5% significance level (the default){p_end}
{phang2}{cmd:. power icc 0.80 0.90, n(60)}

{pstd}
    Compute the power of a one-sided test to detect an ICC of 0.90 given a null ICC of 0.80
	where each of 40 subjects is rated by 4 raters {p_end}
{phang2}{cmd:. power icc 0.80 0.90, n(40) nr(4) onesided}

{pstd}
	Compute powers for a range of sample sizes and number of ratings per subject, 
	graphing the results{p_end}
{phang2}{cmd:. power icc 0.80 0.90, n(20(5)70) nr(2(1)5) graph}


{title:Stored results}

{pstd}
{cmd:power icc} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd: r(alpha)}}significance level{p_end}
{synopt:{cmd: r(icc0)}}null ICC{p_end}
{synopt:{cmd: r(icc1)}}alternative ICC{p_end}
{synopt:{cmd: r(beta)}}probability of a type II error{p_end}
{synopt:{cmd: r(delta)}}effect size{p_end}
{synopt:{cmd: r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}
{synopt:{cmd: r(nr)}}number of raters/ratings{p_end}
{synopt:{cmd: r(N)}}total sample size{p_end}
{synopt:{cmd: r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}
{synopt:{cmd: r(power)}}power{p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}{cmd:icc}{p_end}
{synopt:{cmd:r(columns)}}displayed table columns{p_end}
{synopt:{cmd:r(labels)}}table column labels{p_end}
{synopt:{cmd:r(widths)}}table column widths{p_end}
{synopt:{cmd:r(formats)}}table column formats{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(pss_table)}}table of results{p_end}
{p2colreset}{...}


{title:References}

{p 4 8 2} Shoukri, M. M., Asyali, M. H., & A. Donner. 2004. Sample size requirements for the design of reliability study: review and new results. 
{it:Statistical Methods in Medical Research}. 13: 251-271.

{p 4 8 2} Walter, S. D. Eliasziw, M., & A. Donner. 1998. Sample size and optimal designs for reliability studies. {it:Statistics in Medicine} 17: 101-110.{p_end}

{p 4 8 2} Zou, G. Y. 2012. Sample size formulas for estimating intraclass correlation coefficients with precision and assurance. {it:Statistics in Medicine} 31: 3972-3981. {p_end}



{marker citation}{title:Citation of {cmd:power icc}}

{p 4 8 2}{cmd:power icc} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). POWER ICC: Stata module to compute power and sample size for one-way random-effects intraclass correlation



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb icc}, {helpb power}, {helpb sampicc} (if installed){p_end}

