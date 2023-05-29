{smcl}
{* *! version 1.0.0 22May2023}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col:{hi:power loa} {hline 2}} power and sample size analysis for limits of agreement (LOA)  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:power loa}
{it: mu}
{it: delta}
, {opth sd(numlist)}
[
{opth g:amma(numlist)}
{opth a:lpha(numlist)}
{opth p:ower(numlist)} 
{opth n(numlist)} 
{opt m:ax(#)} 
{opt onesid:ed} ]

{pstd}
{it:mu} is the mean difference between the two measurement methods and {it:delta} 
is the maximum allowable mean difference between the two measurement methods; {it:delta} 
must be a value outside of the LOA. {it:mu} and {it:delta} may each be specified either 
as one number or as a list of values in parentheses (see {help numlist}).{p_end}


{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth sd(numlist)}}specify the expected standard deviation of the sample differences; {cmd:sd() is required}{p_end}
{p2coldent:* {opth g:amma(numlist)}}alpha level of Bland-Altman LOA; default is {cmd:gamma(0.05)} {p_end}
{p2coldent:* {opth a:lpha(numlist)}}alpha level of the LOA confidence intervals; default is {cmd:alpha(0.05)} {p_end}
{p2coldent:* {opth p:ower(numlist)}}power; required to compute sample size. Default is {cmd:power(.80)}{p_end}
{p2coldent:* {opth n(numlist)}}sample size; required to compute power{p_end}
{synopt :{opt m:ax(#)}}maximum number of iterations; default is {cmd:max(100000)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* Specifying a list of values in at least two starred options, or 
two command arguments, or at least one starred option and one argument
results in computations for all possible combinations of the values; see
{help numlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt power loa} computes sample size at a specified power, and power at a specified sample size, for Bland and Altman's (1986) limits of agreement (LOA) analysis, 
according to the method developed by Lu et al. (2016). Briefly, upper and lower confidence limits are computed for both upper and lower LOAs. If the maximum allowable 
mean difference (delta) falls between the upper confidence limit of the upper LOA and the lower confidence limit of the lower LOA, the two measurements are considered 
to be in agreement. Otherwise, they are considered not to be in agreement.  

{pstd}
The results produced by {opt loasampsi} are identical to those produced by the
{browse "https://www.ncss.com/wp-content/themes/ncss/pdf/Procedures/PASS/Bland-Altman_Method_for_Assessing_Agreement_in_Method_Comparison_Studies.pdf":PASS Sample Size Software}
and the R package {browse "https://github.com/nwisn/blandPower/":blandPower}.


{title:Options}

{p 4 8 2} 
{cmd:sd(}{it:#}{cmd:)} specifies the expecteded stardard deviation 
of the sample differences; {cmd:sd() is required}.

{p 4 8 2} 
{opth g:amma(numlist)} sets the significance level for computing the 
LOAs. The default is {cmd:alpha(0.05)}.

{p 4 8 2} 
{opth a:lpha(numlist)} sets the significance level for computing the 
confidence interval of the LOAs. The default is {cmd:alpha(0.05)}.

{p 4 8 2} 
{opth p:ower(numlist)} specifies the desired power at which sample size is to be computed. The actual power 
derived from the analysis is reported in the output when {cmd:n()} is specified.

{p 4 8 2} 
{opth n(numlist)} specifies the desired sample size at which the power is to be computed.

{p 4 8 2} 
{cmd:max(}{it:#}{cmd:)} specifies the maximum number of iterations for the algorithm to run so as to prevent endless looping when a solution cannot be found.
The default is {cmd:max(100000)}.


{title:Examples}

{pstd}
{opt 1) Computing sample size:}{p_end}

{pstd}Based on pilot study data, we find that the mean difference between two lab methods is 2.12, and the standard deviation is 38.77. 
We set our maximimum allowable difference between the methods at 100. We use the default settings for power (80%), gamma (0.05)
and alpha (0.05) {p_end}
{phang2}{cmd:. power loa 2.12 100, sd(38.77)}{p_end}

{pstd}Same as above, but we assess sample size at powers of 80% and 90% {p_end}
{phang2}{cmd:. power loa 2.12 100, sd(38.77) power(.80 .90)} {p_end}

{pstd}Same as above, but we now specify levels of delta ranging from 80 to 100 {p_end}
{phang2}{cmd:. power loa 2.12 (80(1)100), sd(38.77) power(0.80 0.90)} {p_end}

{pstd}Same as above, but we now graph the results {p_end}
{phang2}{cmd:. power loa 2.12 (80(1)100), sd(38.77) power(0.80 0.90) graph(x(delta))} {p_end}


{pstd}
{opt 2) Computing power:}{p_end}

{pstd}Using results from our first example, we specify the sample size as 86, so we can compute the exact power {p_end}
{phang2}{cmd:. power loa 2.12 100, sd(38.77) n(86)}{p_end}

{pstd}We now specify a range of sample sizes {p_end}
{phang2}{cmd:. power loa 2.12 100, sd(38.77) n(60(2)120)}{p_end}

{pstd}We now specify a range of sample sizes {p_end}
{phang2}{cmd:. power loa 2.12 100, sd(38.77) n(60(2)120)}{p_end}

{pstd}Same as above, but we now graph the results {p_end}
{phang2}{cmd:. power loa 2.12 100, sd(38.77) n(60(2)120) graph}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:power loa} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 14 18 2: Scalars}{p_end}
{synopt:{cmd:r(mu)}}mean of differences {p_end}
{synopt:{cmd:r(delta)}}maximum allowable difference{p_end}
{synopt:{cmd:r(sd)}}standard deviation of the difference{p_end}
{synopt:{cmd:r(gamma)}}alpha level for LOA{p_end}
{synopt:{cmd:r(alpha)}}alpha level for LOA confidence intervals{p_end}
{synopt:{cmd:r(power)}}power for the computed sample size{p_end}
{synopt:{cmd:r(N)}}computed sample size{p_end}
{synopt:{cmd:r(lloa)}}lower LOA{p_end}
{synopt:{cmd:r(uloa)}}upper LOA{p_end}
{synopt:{cmd:r(uloaLCL)}}lower confidence limit of upper LOA{p_end}
{synopt:{cmd:r(uloaUCL)}}upper confidence limit of upper LOA{p_end}
{synopt:{cmd:r(lloaLCL)}}lower confidence limit of lower LOA{p_end}
{synopt:{cmd:r(lloaUCL)}}upper confidence limit of lower LOA{p_end}
{synopt:{cmd:r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}
{synopt:{cmd:r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}{cmd:loa}{p_end}
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
Bland, J. M., and D. G. Altman.  1986. Statistical methods for assessing agreement between two methods of clinical measurement. {it:Lancet} I: 307-310.{p_end}

{p 4 8 2}
Lu, M. J.,Zhong, W. H., Liu, Y. X., Miao, H. Z., Li, Y. C. and M. H. Ji. 2016. Sample Size for assessing agreement
between two methods of measurement by Bland-Altman method. {it:The International Journal of Biostatistics}
Article 20150039. (Published online).{p_end}



{marker citation}{title:Citation of {cmd:power loa}}

{p 4 8 2}{cmd:power loa} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). POWER LOA: Stata module to compute power and sample size for limits of agreement (LOA) analysis



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb rmloa} (if installed) {p_end}

