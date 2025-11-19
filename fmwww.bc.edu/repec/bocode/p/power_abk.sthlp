{smcl}
{* *! version 1.0.0 14Nov2025}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col:{hi:power abk} {hline 2}} power analysis for a balanced (AB)^k design with multiple cases {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Compute sample size:

{p 8 12 2}
{cmd:power abk}, 
{opth pow:er(numlist)} 
{opth d:elta(numlist)}
{opth pha:ses(numlist)}
{opth m:obs(numlist)}
{opth icc(numlist)}
{opth p:hi(numlist)} 
{opt [ }{opth a:lpha(numlist)}
{opt onesid:ed} 
{opt  ]}  {p_end}
{p 12 14 2}


{pstd}
Compute power:

{p 8 12 2}
{cmd:power abk}, 
{opth n(numlist)} 
{opth d:elta(numlist)}
{opth pha:ses(numlist)}
{opth m:obs(numlist)}
{opth icc(numlist)}
{opth p:hi(numlist)} 
{opt [ }{opth a:lpha(numlist)}
{opt onesid:ed} 
{opt  ]}  {p_end}
{p 12 14 2}


{pstd}
Compute effect size:

{p 8 12 2}
{cmd:power abk},
{opth n(numlist)}  
{opth pow:er(numlist)} 
{opth pha:ses(numlist)}
{opth m:obs(numlist)}
{opth icc(numlist)}
{opth p:hi(numlist)} 
{opt [ }{opth a:lpha(numlist)}
{opt onesid:ed} 
{opt  ]}  {p_end}
{p 12 14 2}



{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth n(numlist)}}total sample size; required to compute power or effect size{p_end}
{p2coldent:* {opth pow:er(numlist)}}power; required to compute sample size or effect size {p_end}
{p2coldent:* {opth d:elta(numlist)}}standardized mean difference between treatment and control phases; required to compute sample size or power {p_end}
{p2coldent:* {opth pha:ses(numlist)}}number of AB phase repetitions ({it:k}; required {p_end}
{p2coldent:* {opth m:obs(numlist)}}number of observations {it:M} per phase; required {p_end}
{p2coldent:* {opth icc(numlist)}}intraclass correlation; required {p_end}
{p2coldent:* {opth p:hi(numlist)}}autocorrelation; required {p_end}
{p2coldent:* {opth a:lpha(numlist)}}significance level; default is {cmd:alpha(0.05)} {p_end}
{synopt :{opt onesid:ed}}one-sided test; default is two sided {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* Specifying a list of values in at least two starred options results in computations for all possible combinations of the values; see {helpb numlist}{p_end}



{marker description}{...}
{title:Description}

{pstd}
{opt power abk} computes power, sample size and effect size for tests that compare treatment and control means in
a balanced (AB)^k design with multiple cases, using the calculations given in Hedges, Shadish, and Batley (2022). In 
the balanced (AB)^k design, {it:A} refers to a baseline (control or reference) phase, {it:B} refers to a treatment
phase, and {it:k} indicates the number of times (phases) the AB pair is repeated. During each phase, {it:M} measurements are
taken. For example, (AB)^2 indicates an ABAB design in which 4M measurements are taken on each subject. 2M
of these are control measurements and 2M are treatment measurements (i.e., the design is balanced with 2M measurements 
in each phase). See the {browse "https://www.ncss.com/wp-content/themes/ncss/pdf/Procedures/PASS/Tests_for_the_Difference_Between_Treatment_and_Control_Means_in_a_Balanced_Single-Case-ABK_Design_with_Multiple_Cases.pdf":PASS Sample Size Software} 
entry for greater detail. Also, the paper by Hedges, Shadish, and Batley (2022) comes with an R program. The results produced by {cmd:power abk} are identical to those produced by the R code.  



{title:Options}

{p 6 8 2} 
{opth n(numlist)} specifies the total number of subjects in the study to be used for power or effect-size determination. If {cmd:n()} and 
{cmd:delta()} are specified, the power is computed. If {cmd:n()} and {cmd:power()} are specified, the minimum effect size 
(standardized mean difference) that is likely to be detected in a study is computed.

{p 6 8 2} 
{opth pow:er(numlist)} sets the power of the test; required to compute sample size or effect size. 

{p 6 8 2} 
{opth d:elta(numlist)} specifies the standardized mean difference between the control-phase mean and the treatment-phase mean; required 
to compute sample size or power. 

{p 6 8 2} 
{opth pha:ses(numlist)} the number of times (phases) the AB pair is repeated; {cmd: phases()} is required.   

{p 6 8 2} 
{opth m:obs(numlist)} the number of measurements taken in each phase; {cmd: mobs()} is required.   

{p 6 8 2} 
{opth icc(numlist)} the intraclass correlation -- the proportion of the total variance of an observation that is between subjects; {cmd: mobs()} 
is required. 

{p 6 8 2} 
{opth p:hi(numlist)} the autocorrelation between measurements of an individual within each phase; {cmd: phi()} is required.   

{p 6 8 2} 
{opth a:lpha(numlist)} significance level. The default is {cmd:alpha(0.05)}.

{p 6 8 2} 
{opt onesid:ed} indicates a one-sided test. The default is two sided.



{title:Examples}

{pstd}
{cmd:{ul:Computing sample-size:}}{p_end}

{pstd} Compute the total sample size required to detect a standardized mean difference between the control and treatment phases of 0.75, 
assuming there will be two phases (ABAB), with three measurements taken in each phase, an ICC of 0.5 and autocorrelation of 0.5. 
A two-sided test with a 5% significance level will be used, and power is set to 80%.{p_end}

{phang2}{cmd:. power abk, phases(2) mobs(3) delta(0.75) icc(0.5) phi(0.5) alpha(0.05) power(0.80)}{p_end}

{pstd}Same as above, but we now add an alpha level of 0.01 and an additional power of 0.90 and graph the results{p_end}

{phang2}{cmd:. power abk, phases(2) mobs(3) delta(0.75) icc(0.5) phi(0.5) alpha(0.05 0.01) power(0.80 0.90) graph}{p_end}

{pstd}
{cmd:{ul:Computing power:}}{p_end}

{pstd}Suppose we have a sample of 3 subjects, and we want to compute the power of a two-sided test to detect an standardized mean difference between control-phase
and treatment-phase means of 0.75; where three measurements will be taken in each of the 2 phases. The ICC and autocorrelation are both set to 0.5 and alpha is 0.05{p_end}

{phang2}{cmd:. power abk, n(3) phases(2) mobs(3) delta(0.75) icc(0.5) phi(0.5) alpha(0.05)} {p_end}

{pstd}We assess power for a range of sample sizes and graph the results {p_end}

{phang2}{cmd:. power abk, n(2(1)15) phases(2) mobs(3) delta(0.75) icc(0.5) phi(0.5) alpha(0.05) graph} {p_end}

{pstd}Same as above but add an additional alpha of 0.01{p_end}

{phang2}{cmd:. power abk, n(2(1)15) phases(2) mobs(3) delta(0.75) icc(0.5) phi(0.5) alpha(0.05 0.01) graph} {p_end}


{pstd}
{cmd:{ul:Computing effect size:}}{p_end}

{pstd}We are interested in finding the standardized mean difference between the 2 control and the treatment phases with a sample size of 3
subjects, each getting measured 3 times in each phase. The ICC and autocorrelation are both set to 0.5, power to 80% and alpha to 0.05. {p_end}

{phang2}{cmd:. power abk, n(3) phases(2) mobs(3) icc(0.5) phi(0.5) alpha(0.05) power(0.80)}{p_end}

{pstd}Same as above but we add power of 90% and alpha of 0.01{p_end}

{phang2}{cmd:. power abk, n(3) phases(2) mobs(3) icc(0.5) phi(0.5) alpha(0.05 0.01) power(0.80 0.90)}{p_end}

{pstd}We now determine effect sizes for a range of sample sizes and graph the results {cmd:(note: this may take a minute or two to compute)}{p_end}

{phang2}{cmd:. power abk, n(3(1)10) phases(2) mobs(3) icc(0.5) phi(0.5) alpha(0.05) power(0.80) graph}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:power abk} stores the following in {cmd:r()}:

{synoptset 17 tabbed}{...}

{p2col 5 14 18 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}computed sample size{p_end}
{synopt:{cmd:r(power)}}power for the computed sample size{p_end}
{synopt:{cmd:r(beta)}}probability of a type II error{p_end}
{synopt:{cmd:r(delta)}}effect size{p_end}
{synopt:{cmd:r(alpha)}}significance level{p_end}
{synopt:{cmd:r(phases)}}number of AB pairs{p_end}
{synopt:{cmd:r(mobs)}}number of measurements taken in each phase{p_end}
{synopt:{cmd:r(icc)}}intraclass correlation{p_end}
{synopt:{cmd:r(phi)}}autocorrelation{p_end}
{synopt:{cmd:r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}
{synopt:{cmd:r(separator)}}number of lines between separator lines in the table{p_end}
{synopt:{cmd:r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}

{synoptset 17 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}{cmd:abk}{p_end}
{synopt:{cmd:r(direction)}}{cmd:upper} or {cmd:lower}{p_end}
{synopt:{cmd:r(columns)}}displayed table columns{p_end}
{synopt:{cmd:r(labels)}}table column labels{p_end}
{synopt:{cmd:r(widths)}}table column widths{p_end}
{synopt:{cmd:r(formats)}}table column formats{p_end}
{synopt:{cmd:r(solve_for)}}{cmd:N} or {cmd:power} or {cmd:delta}{p_end}

{synoptset 17 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(pss_table)}}table of results{p_end}
{p2colreset}{...}



{title:References}

{phang}
Hedges, L. V., Shadish, W. R., & P. N. Batley. 2023.
Power analysis for single-case designs: Computations of (AB)k designs.
{it:Behavior Research Methods}
55: 3494–3503



{marker citation}{title:Citation of {cmd:power abk}}

{p 4 8 2}{cmd:power abk} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). POWER ABK: Stata module to perform power analysis for a balanced (AB)^k design with multiple cases



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb power} {p_end}

