{smcl}
{* *! version 1.0.0 17Aug2022}{...}
{title:Title}

{p2colset 5 25 26 2}{...}
{p2col:{hi:power diagnostic} {hline 2}} Power and sample-size analysis for sensitivity and specificity of a diagnostic test  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Compute sample size

{p 8 16 2}
{cmd:power} {help power_diagnostic##method:{it:method}}
...
[{cmd:,} {opth p:ower(numlist)}
{help power_diagnostic##power_options:{it:power_options}} ...]


{pstd}
Compute power

{p 8 16 2}
{cmd:power} {help power_diagnostic##method:{it:method}}
...{cmd:,} {opth n(numlist)}
[{help power_diagnostic##power_options:{it:power_options}} ...]


{marker method}{...}
{synoptset 30 tabbed}{...}
{synopthdr :method}
{synoptline}
{syntab:One sample}
{synopt :{helpb power onesens:onesens}}One-sample test for sensitivity{p_end}
{synopt :{helpb power onespec:onespec}}One-sample test for specificity{p_end}

{syntab:Two independent samples}
{synopt :{helpb power twosens:twosens}}Two-sample test for sensitivity {p_end}
{synopt :{helpb power twospec:twospec}}Two-sample test for specificity {p_end}

{syntab:Two paired samples}
{synopt :{helpb power pairsens:pairsens}}paired test for sensitivity {p_end}
{synopt :{helpb power pairspec:pairspec}}paired test for specificity {p_end}
{synoptline}

{marker power_options}{...}
{synopthdr :power_options}
{synoptline}
{syntab:Main}
{p2coldent:* {opth a:lpha(numlist)}}significance level; default is {cmd:alpha(0.05)} {p_end}
{p2coldent:* {opth p:ower(numlist)}}power; default is {cmd:power(0.80)} {p_end}
{p2coldent:* {opth n(numlist)}}total sample size; required to compute power {p_end}
{p2coldent:* {opth prev(numlist)}}prevalence rate of disease in the population under study; default is {cmd:prev(0.50)} {p_end}
{p2coldent:* {opth frac:tion(numlist)}}fraction of the sample assigned to test 1 in {helpb power twosens:twosens} and {helpb power twospec:twospec}; default is {cmd:fraction(0.50)}  {p_end}
{synopt :{opt onesid:ed}}one-sided test; default is two sided{p_end}
{synopt :{cmdab:gr:aph}[{cmd:(}{it:{help power_optgraph##graphopts:graphopts}}{cmd:)}]}graph results; see {manhelp power_optgraph PSS-2:power, graph}{p_end}
{synopt :{opt init(#)}}initial value of the estimated power; default is {cmd:init(10)} {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* Specifying a list of values in at least two starred options, or 
two command arguments, or at least one starred option and one argument
results in computations for all possible combinations of the values; see
{help numlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
The {cmd:power diagnostic} suite of commands is useful for planning prospective studies evaluating the accuracy of diagnostic tests for a binary outcome
(e.g. diseased/not-diseased) and in which a test's sensitivity and specificity are the measures of interest. {it: Sensitivity} is the probability
of a test detecting disease when the patient actually has the disease, and {it:specificity} is the probability that the test is negative 
when the patient is actually disease-free. 

{pstd}
All {cmd:power diagnostic} commands implement the naive prevalence inflation method introduced by 
Obuchowski and Zhou (2002). Li and Fine (2004) found this method (which they refer to as "Method 0") to be a useful approximation to exact sample-size
calculations based on unconditional power, which are more computationally intensive.   

{pstd}
Sample size can be computed given power, and power can be computed given sample size. Results can be displayed in a table (default) and on a graph 
({helpb power_optgraph:[PSS-2] power, graph}).  


{marker options}{...}
{title:Options}

{marker mainopts}{...}
{dlgtab:Main}

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
{opth fraction(numlist)} specifies the fraction of the sample assigned to test 1 in {helpb power twosens:twosens} 
and {helpb power twospec:twospec}. The default is {cmd:fraction(0.50)} (i.e. half the sample).

{phang} 
{cmd:onesided} indicates a one-sided test. The default is two sided. 

{dlgtab:Graph}

{phang}
{cmd:graph} and {cmd:graph()} produce graphical output; see
{helpb power_optgraph:[PSS-2] power, graph} for details.

{marker iteropts}{...}
{dlgtab:Iteration}

{phang}
{opt init(#)} specifies an initial value for estimating power in {helpb power twosens:twosens},
{helpb power twospec:twospec}, {helpb power pairsens:pairsens}, {helpb power pairspec:pairspec}. 
The default value is {cmd:init(10)} which is a rescaled value of power = 0.001 (10/10,000). 
Increasing the initial value may be helpful if the reported power appears unreasonably low (e.g. 0.001).    


{marker examples}{...}
{title:Examples}

    {title:Examples: One-sample test of sensitivity}

{pstd}
    Compute the sample size required to detect a sensitivity of 0.90 given a
    sensitivity of 0.70 under the null hypothesis using a two-sided test;
    assume a 5% significance level, 80% power and a conjectured disease prevalence of 0.50 (the defaults) {p_end}
{phang2}{cmd:. power onesens 0.70 0.90} 
    
{pstd}
    For a total sample of 300 subjects, compute the power of a two-sided test to 
    detect a sensitivity of 0.90 given a null sensitivity of 0.70; assume a 1%
    significance level and a prevalence of 0.20{p_end}
{phang2}{cmd:. power onesens 0.70 0.90, n(300) prev(0.20) alpha(0.01)}


    {title:Examples: One-sample test of specificity}

{pstd}
    Compute the sample size required to detect a specificity of 0.90 given a
    specificity of 0.80 under the null hypothesis using a two-sided test;
    assume a 5% significance level, 90% power and a conjectured disease prevalence of 0.10 {p_end}
{phang2}{cmd:. power onespec 0.80 0.90, power(0.90) prev(0.10) } 

{pstd}
    For a total sample of 40 subjects, compute the power of a two-sided test to 
    detect a specificity of 0.90 given a null specificity of 0.70; assume a 5%
    significance level and a prevalence of 0.20{p_end}
{phang2}{cmd:. power onespec 0.70 0.90, n(40) prev(0.20) }


    {title:Examples: Two-sample test of sensitivity}

{pstd}
    Compute the sample size required to detect a statistical difference in sensitivity between
	two tests, where the first test is hypothesized to have a sensitivity of 0.70 and the second
	test is hypothesized to have a sensitivity of 0.90 using a two-sided test;
    assume a 5% significance level, 80% power, a conjectured disease prevalence of 0.30,
	and 50% of the sample assigned to test 1 (the default) {p_end}
{phang2}{cmd:. power twosens 0.70 0.90, prev(0.30)} 

{pstd}
    For a total sample of 400 subjects, compute the power of a two-sided test to 
    detect a sensitivity of 0.90 given a null sensitivity of 0.70; assume a 5%
    significance level, a prevalence of 0.30, and a 1:3 ratio of test 1 to test 2 (e.g. 0.25/0.75) {p_end}
{phang2}{cmd:. power twosens 0.70 0.90, n(400) prev(0.30) fract(0.25)}


    {title:Examples: Two-sample test of specificity}

{pstd}
    Compute the sample size required to detect a statistical difference in specificity between
	two tests, where the first test is hypothesized to have a specificity of 0.85 and the second
	test is hypothesized to have a specificity of 0.95 using a two-sided test;
    assume a 5% significance level, 90% power, a conjectured disease prevalence of 0.30,
	and 50% of the sample assigned to test 1 (the default) {p_end}
{phang2}{cmd:. power twospec 0.85 0.95, prev(0.30) power(0.90)} 

{pstd}
    For a total sample of 500 subjects, compute the power of a two-sided test to 
    detect a specificity of 0.95 given a null specificity of 0.85; assume a 5%
    significance level a prevalence of 0.25, and a 1:2 ratio of test 1 to test 2 (e.g. 0.3334/0.6667) {p_end}
{phang2}{cmd:. power twospec 0.85 0.95, n(500) prev(0.25) fract(0.3334)}


    {title:Examples: Paired-sample test of sensitivity}
	
{pstd}
    Compute the sample size required to detect a statistical difference in sensitivity between
	two tests (where the same subjects take both tests), where the first test is hypothesized 
	to have a sensitivity of 0.82 and the second test is hypothesized to have a sensitivity 
	of 0.90 using a one-sided test; assume a 5% significance level, 80% power, and a conjectured 
	disease prevalence of 0.10 {p_end}
{phang2}{cmd:. power pairsens 0.82 0.90, prev(0.10) onesided} 	

{pstd}
    For a total sample of 3000 subjects, compute the power of a two-sided test to 
    detect a sensitivity of 0.90 given a null sensitivity of 0.82; assume a 5%
    significance level and a prevalence of 0.10{p_end}
{phang2}{cmd:. power pairsens 0.82 0.90, n(3000) prev(0.10) }


    {title:Examples: Paired-sample test of specificity}

{pstd}
    Compute the sample size required to detect a statistical difference in specificity between
	two tests (where the same subjects take both tests), where the first test is hypothesized 
	to have a specificity of 0.70 and the second test is hypothesized to have a specificity 
	of 0.80 using a two-sided test; assume a 1% significance level, 90% power, and a conjectured 
	disease prevalence of 0.09 {p_end}
{phang2}{cmd:. power pairspec 0.70 0.80, alpha(0.01) power(0.90) prev(0.09)} 

{pstd}
    For a total sample of 550 subjects, compute the power of a two-sided test to 
    detect a specificity of 0.80 given a null specificity of 0.70; assume a 1%
    significance level and a prevalence of 0.10{p_end}
{phang2}{cmd:. power pairspec 0.70 0.80, n(550) prev(0.10) alpha(0.01)}


{marker results}{...}
{title:Stored results}


{pstd}
{cmd:power diagnostic} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd: r(alpha)}}significance level{p_end}
{synopt:{cmd: r(power)}}power{p_end}
{synopt:{cmd: r(beta)}}probability of a type II error{p_end}
{synopt:{cmd: r(sens0)}}null sensitivity (only available in {helpb power onesens:onesens}){p_end}
{synopt:{cmd: r(sens1)}}sensitivity of test 1{p_end}
{synopt:{cmd: r(sens2)}}sensitivity of test 2{p_end}
{synopt:{cmd: r(spec0)}}null specificity (only available in {helpb power onespec:onespec}){p_end}
{synopt:{cmd: r(spec1)}}specificity of test 1{p_end}
{synopt:{cmd: r(spec2)}}specificity of test 2{p_end}
{synopt:{cmd: r(delta)}}effect size{p_end}
{synopt:{cmd: r(prev)}}prevalence of disease{p_end}
{synopt:{cmd: r(fraction)}}fraction of sample assigned to test 1 (available in {helpb power twosens:twosens} and {helpb power twospec:twospec}){p_end}
{synopt:{cmd: r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}
{synopt:{cmd: r(init)}}initial value of the estimated power (available in {helpb power twosens:twosens}, {helpb power twospec:twospec}, {helpb power pairsens:pairsens}, {helpb power pairspec:pairspec}) {p_end}
{synopt:{cmd: r(N)}}total sample size{p_end}
{synopt:{cmd: r(N0)}}sample size of the non-diseased group{p_end}
{synopt:{cmd: r(N1)}}sample size of the diseased group{p_end}
{synopt:{cmd: r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}method name{p_end}
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


{marker citation}{title:Citation of {cmd:power diagnostic}}

{p 4 8 2}{cmd:power diagnostic} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, A. 2022. POWER DIAGNOSTIC: Stata package to compute power and sample size for sensitivity and specificity of a diagnostic test


{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb estat classification}, {helpb lsens}, {helpb power}, {helpb power onesens} (if installed),
{helpb power onespec} (if installed), {helpb power twosens} (if installed), {helpb power twospec} (if installed), 
{helpb power pairsens} (if installed), {helpb power pairspec} (if installed){p_end}

