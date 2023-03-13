{smcl}
{* Copyright 2012-2018 Brendan Halpin brendan.halpin@ul.ie }
{* Distribution is permitted under the terms of the GNU General Public Licence }
{* 26Oct2018}{...}
{cmd:help ari}
{hline}

{title:Title}

{p2colset 5 17 23 2}{...}
{p2col:{hi:ari} {hline 2}}Calculate the Adjuted Rand Index for a pair of unlabelled classifications{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:ari} {it: var1 var2} [if] [in] [, Permute(real)]

{title:Description}

{pstd}{cmd:ari} takes a pair of unlabelled classifications (e.g., two
cluster solutions) and returns the Adjusted Rand Index, which has a
maximum of 1 for perfect agreement, and where zero means no relationship. Returns r(ari). 
{p_end}

{title:Options}

{p 0 4}{cmd:Permute(}N{cmd:)} Carry out a permutation test with N draws.{p_end}

{title:Comments}

{p} The permutation test tests against the null hypothesis that the
classifications are independent. It returns r(arip), which is the
probability of observing an ARI this high or higher if the null is true,
and r(arip95), the 95 percentile of the permuted ARIs. {p_end}


{title:References}

{p 4 4 2}
N Xuan Vinh, J Epps and J Bailey (2009), Information Theoretic Measures for Clusterings Comparison: Is a
Correction for Chance Necessary?, {it:Proceedings of the 26th International Conference on Machine Learning},
Montreal, Canada

{p 4 4 2}
L. Hubert and P Arabie (1985), Comparing Partitions, {it:Journal of Classification} 2(1), pp 193-218


{title:Author}

{phang}Brendan Halpin, brendan.halpin@ul.ie{p_end}


{title:Examples}

{phang}{cmd:. ari a8 b8}{p_end}

