{smcl}
{* *! version 1.0.0 13Oct2021}{...}
{title:Title}

{p2colset 5 21 22 2}{...}
{p2col:{hi:ordcatsampsi} {hline 2}} power and sample size analysis for ordered categorical outcomes  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:ordcatsampsi}
{it: probabilities}
, {opt or(#)}
[
{opt alp:ha(#)}
{opt p:ower(#)}
{opt n(#)} 
{opt n1(#)} 
{opt n2(#)}
{opt nrat:io(#)}
{opt onesid:ed}
]

{pstd}
{it:proportions} is a list of proportions which must add up to one. The {it:i}th element specifies the probability that an individual will be in outcome level {it:i}, averaged over the two treatment groups.



{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt or(#)}}the expected odds ratio of the treatment effect; {cmd:or() is required}{p_end}
{synopt :{opt alp:ha(#)}}set the significance level; default is {cmd:alpha(0.05)}{p_end}
{synopt :{opt p:ower(#)}}the desired power; {cmd:power()} cannot be specified together with {cmd:n()}, {cmd:n1()} or {cmd:n2()} {p_end}
{synopt :{opt n(#)}}the total sample size; {cmd:n()} cannot be specified together with {cmd:power()}{p_end}
{synopt :{opt n1(#)}}sample size of the control group; {cmd:n()} cannot be specified together with {cmd:power()}{p_end}
{synopt :{opt n2(#)}}sample size of the experimental group; {cmd:n()} cannot be specified together with {cmd:power()}{p_end}
{synopt :{opt nrat:io(#)}}ratio of sample sizes, {opt N2/N1}; default is {opt nratio(1)}, meaning equal group sizes {p_end}
{synopt :{opt onesid:ed}}one-sided test; default is two sided{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}



{marker description}{...}
{title:Description}

{pstd}
{opt ordcatsampsi} computes sample size at a specified power, and power at a specified sample size, for a two sample comparison of ordinal outcomes under the proportional odds ordinal logistic model. The power is the same as that of the Wilcoxon test but with ties handled properly. {opt ordcatsampsi} uses the methods of Whitehead (1993) and produces identical results as those produced by the R package {browse "https://rdrr.io/cran/Hmisc/man/popower.html":popower}.



{title:Options}

{p 4 8 2} 
{cmd:or(}{it:#}{cmd:)} specifies the expected odds ratio (treatment effect); {cmd:or() is required}.

{p 4 8 2} 
{cmd:alpha(}{it:#}{cmd:)} sets the significance level of the test. The default is {cmd:alpha(0.05)}.

{p 4 8 2} 
{cmd:power(}{it:#}{cmd:)} specifies the desired power at which sample size is to be computed. 
{cmd:power()} cannot be specified together with {cmd:n()}, {cmd:n1()}, or {cmd:n2()}.

{p 4 8 2} 
{cmd:n(}{it:#}{cmd:)} specifies the total number of subjects in the study to be used for determining power.
{cmd:n()} cannot be specified together with {cmd:power()}. 

{p 4 8 2} 
{cmd:n1(}{it:#}{cmd:)} specifies the number of subjects in the control group to be used for determining power. 
{cmd:n1()} cannot be specified together with {cmd:power()}.

{p 4 8 2} 
{cmd:n2(}{it:#}{cmd:)} specifies the number of subjects in the experimental group to be used for determining power.
{cmd:n2()} cannot be specified together with {cmd:power()}.

{p 4 8 2} 
{cmd:nratio(}{it:#}{cmd:)} specifies the sample-size ratio of the experimental group relative to the control group, 
{cmd:N2/N1}, for two-sample tests. The default is {cmd:nratio(1)}, meaning equal allocation between the two groups.

{p 4 8 2} 
{cmd:onesided(}{it:#}{cmd:)} indicates a one-sided test. The default is two sided. 



{title:Examples}

{pstd}
{opt 1) Computing sample size:}{p_end}

{pstd}Using the worked example in Campbell et al (1995), the 4 categories are "normal", "slightly listless", "moderately listless", and "very listless", and their respective 
proportions are 0.14, 0.24, 0.24, and 0.38. The expected odds ratio is 0.33, and we want an equal number of subjects in both groups with power set to 0.80 and alpha 0.05. {p_end}
{phang2}{cmd:. ordcatsampsi 0.14 0.24 0.24 0.38, or(.33) nratio(1) power(0.80) alpha(0.05)}{p_end}

{pstd}
{opt 2) Computing power:}{p_end}

{pstd}Same as above but we specify total n = 84 to find the power at that sample size. {p_end}
{phang2}{cmd:. ordcatsampsi 0.14 0.24 0.24 0.38, or(.33) n(84)}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ordcatsampsi} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 14 18 2: Scalars}{p_end}
{synopt:{cmd:r(power)}}estimated power {p_end}
{synopt:{cmd:r(n)}}computed total sample size{p_end}
{synopt:{cmd:r(n1)}}computed sample size of control group{p_end}
{synopt:{cmd:r(n2)}}computed sample size of experimental group{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2} Campbell, M. J., Julious, S. A. and Altman, D. G. 1995. Sample sizes for binary, ordered categorical and continuous outcomes in two group comparions. 
{it:British Medical Journal} 311:1145-1148.

{p 4 8 2} Whitehead, J. 1993. Sample size calculations for ordered categorical data. {it:Statistics in Medicine} 12:2257–2271.{p_end}



{marker citation}{title:Citation of {cmd:ordcatsampsi}}

{p 4 8 2}{cmd:ordcatsampsi} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2021). ORDCATSAMPSI: Stata module to compute power and sample size for ordered categorical outcomes



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb power} {helpb ologit} {p_end}

