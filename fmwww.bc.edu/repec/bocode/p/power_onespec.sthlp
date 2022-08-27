{smcl}
{* *! version 1.0.0 03Aug2022}{...}
{title:Title}

{p2colset 5 22 23 2}{...}
{p2col:{hi:power onespec} {hline 2}} Power and sample-size analysis for specificity of a one-sample diagnostic test  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
Compute sample size

{p 8 43 2}
{opt power onespec} {it:spec0} {it:spec1}
[{cmd:,} {opth p:ower(numlist)} {opth a:lpha(numlist)} {opth prev(numlist)} {opt onesid:ed} {opt gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}] ]

{phang}
Compute power 

{p 8 43 2}
{opt power onespec} {it:spec0} {it:spec1}
[{cmd:,} {opth n(numlist)} {opth a:lpha(numlist)} {opth prev(numlist)} {opt onesid:ed} {opt gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}] ]


{phang}
where {it:spec0} is the null (hypothesized) specificity, and
{it:spec1} is the alternative (target) specificity.
{it:spec0} and {it:spec1} may each be specified either as one 
number or as a list of values in parentheses (see {help numlist}).{p_end}



{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth a:lpha(numlist)}}significance level; default is {cmd:alpha(0.05)} {p_end}
{p2coldent:* {opth p:ower(numlist)}}power; default is {cmd:power(0.80)} {p_end}
{p2coldent:* {opth n(numlist)}}total sample size; required to compute power {p_end}
{p2coldent:* {opth prev(numlist)}}prevalence rate of disease in the population under study; default is {cmd:prev(0.50)}  {p_end}
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
{opt power onespec} computes sample size or power for one-sample specificity of a diagnostic test,
accounting for the prevalence of the disease in the clinical population. Specificity is the ability 
of a test to correctly identify non-diseased patients. 

{pstd}
{opt power onespec} implements the naive prevalence inflation method introduced by Obuchowski and Zhou (2002). 
Li and Fine (2004) found this method (which they refer to as "Method 0") to be a useful approximation 
to exact sample-size calculations based on unconditional power, which are more computationally intensive. 
   


{title:Options}

{phang}
{opth alpha(numlist)} sets the significance level of the test.  The
default is {cmd:alpha(0.05)}.

{phang} 
{opth power(numlist)} specifies the desired power at which sample size is to be computed. 
The default is {cmd:power(0.80)}. If {cmd:power()} is specified in conjunction with {cmd:n()}, 
then the actual power of the test is presented. 

{phang} 
{opth n(numlist)} specifies the total number of subjects in the study to be used for determining power. 

{phang}
{opth prev(numlist)} specifies the conjectured prevalence of the disease in the clinical population. The default is {cmd:prev(0.50)}.

{phang} 
{cmd:onesided} indicates a one-sided test. The default is two sided. 

{phang}
{cmd:graph}, {cmd:graph()}; see {manhelp power_optgraph PSS-2: power, graph}.



{title:Examples}

    {title:Examples: Computing sample size}

{pstd}
    Compute the sample size required to detect a specificity of 0.90 given a
    specificity of 0.70 under the null hypothesis using a two-sided test;
    assume a 5% significance level, 80% power and a conjectured disease prevalence of 0.50 (the defaults) {p_end}
{phang2}{cmd:. power onespec 0.70 0.90} 

{pstd}
    Same as above, using a power of 90%, a one-sided test, and a prevalence of 0.10 {p_end}
{phang2}{cmd:. power onespec 0.70 0.90, power(0.90) prev(0.10) onesided}

{pstd}
    Computing sample size for a range of prevalence rates {p_end}
{phang2}{cmd:. power onespec 0.70 0.90, power(0.90) prev(0.10(.10).90) onesided}

{pstd}
    Applying a range of specificity values under the alternative hypothesis
	and setting alpha levels to 0.05 and 0.01 with a prevalence of 0.10. Here we graph the results {p_end}
{phang2}{cmd:. power onespec (0.60(0.05).80) 0.90, power(0.90) onesided alpha(0.01 0.05) prev(0.10) graph}


    {title:Examples: Computing power}

{pstd}
    For a total sample of 50 subjects, compute the power of a two-sided test to 
    detect a specificity of 0.90 given a null specificity of 0.70; assume a 5%
    significance level and a prevalence of 0.50 (the default){p_end}
{phang2}{cmd:. power onespec 0.70 0.90, n(50)}

{pstd}
    Same as above, but change the prevalence to 0.20 and use a one-sided test {p_end}
{phang2}{cmd:. power onespec 0.70 0.90, n(50) prev(0.20) onesided }

{pstd}
    Same as above, but apply a range prevalence rates {p_end}
{phang2}{cmd:. power onespec 0.70 0.90, n(50) prev(0.20 0.50 0.70) onesided }

{pstd}
	Compute powers for a range of null specificities and total sample sizes, 
	graphing the results{p_end}
{phang2}{cmd:. power onespec (0.60(.10)0.80) 0.90, n(5(5)80) onesided graph}


{title:Stored results}

{pstd}
{cmd:power onespec} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd: r(alpha)}}significance level{p_end}
{synopt:{cmd: r(power)}}power{p_end}
{synopt:{cmd: r(beta)}}probability of a type II error{p_end}
{synopt:{cmd: r(spec0)}}null specificity{p_end}
{synopt:{cmd: r(spec1)}}alternative sensitivity{p_end}
{synopt:{cmd: r(delta)}}effect size{p_end}
{synopt:{cmd: r(prev)}}prevalence of disease{p_end}
{synopt:{cmd: r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}
{synopt:{cmd: r(N)}}total sample size{p_end}
{synopt:{cmd: r(N0)}}sample size of the non-diseased group{p_end}
{synopt:{cmd: r(N1)}}sample size of the diseased group{p_end}
{synopt:{cmd: r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}{cmd:onespec}{p_end}
{synopt:{cmd:r(columns)}}displayed table columns{p_end}
{synopt:{cmd:r(labels)}}table column labels{p_end}
{synopt:{cmd:r(widths)}}table column widths{p_end}
{synopt:{cmd:r(formats)}}table column formats{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(pss_table)}}table of results{p_end}
{p2colreset}{...}


{title:References}

{p 4 8 2} Li, J. and J. Fine. 2004. On sample size for sensitivity and specificity in prospective diagnostic accuracy studies. {it: Statistics in Medicine} 23:2537-2550.{p_end}

{p 4 8 2} Obuchowski, N.A. and X. H. Zhou. 2002. Prospective studies of diagnostic test accuracy when disease prevalence is low. {it:Biostatistics} 3:477-492.{p_end}


{marker citation}{title:Citation of {cmd:power onespec}}

{p 4 8 2}{cmd:power onespec} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, A. 2022. POWER ONESPEC: Stata module to compute power and sample size for specificity of a one-sample diagnostic test



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb estat classification}, {helpb lsens}, {helpb power}, {helpb power onesens} (if installed), 
{helpb power twosens} (if installed), {helpb power twospec} (if installed), {helpb power pairsens} (if installed), 
{helpb power pairspec} (if installed){p_end}

