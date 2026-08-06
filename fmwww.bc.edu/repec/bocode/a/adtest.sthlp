{smcl}
{* *! version 1.2.0  24jul2026}{...}

{title:Title}

{p2colset 5 16 17 2}{...}
{p2col:{hi:adtest} {hline 2}}{it:k}-sample Anderson-Darling equality-of-distributions test {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:adtest}
{varname} {ifin} {weight} {cmd:,} {opth "by(varlist:groupvar)"}
[{cmd:,}
{opt r:eps(#)}
{opt seed(#)}
{opt p:ower(#)}
{opt do:ts}
{opt gr:aph}
{opt post:hoc}]

{pstd}
{it:{help varlist:groupvar}} must take on
{it:k} >= 2 distinct values. The distribution of {it:varname} is compared
across all {it:k} groups simultaneously, each against the pooled empirical
distribution.



{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth "by(varlist:groupvar)"}}specify a variable that identifies the {it:k} groups ({it:k} >= 2){p_end}
{synopt :{opt r:eps(#)}}perform # Monte Carlo permutations; default is {opt reps(1000)}{p_end}
{synopt :{opt seed(#)}}set random-number seed to #{p_end}
{synopt :{opt p:ower(#)}}specify the exponent for the A^2 statistic; default is {opt power(2)}{p_end}
{synopt :{opt do:ts}}display permutation progress dots; default is off{p_end}
{synopt :{opt gr:aph}}plot the empirical CDFs of the {it:k} groups against the pooled empirical CDF, with the cumulative A^2 contribution below{p_end}
{synopt :{opt post:hoc}}also report pairwise comparisons between every pair of groups, with Bonferroni, Holm, and FDR adjusted p-values{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt Required}{p_end}
{p 4 6 2}
{cmd:aweight}s, {cmd:pweight}s, and {cmd:iweight}s are
allowed; see {help weight}.{p_end}



{title:Description}

{pstd}
{cmd:adtest} performs a (optionally weighted) {it:k}-sample Anderson-Darling
(AD) permutation test to assess whether {it:k} >= 2 samples come from the
same distribution, as proposed by Scholz and Stephens (1987). It is the {it:k}-sample 
generalization of the two-sample Anderson and Darling test (1952).
When {it:k} > 2, there is no single pairwise comparison to make, so
{cmd:adtest} instead compares each group's empirical CDF to the
(weighted) pooled empirical CDF of all groups combined. 

{title:Remarks}

{pstd}
When weights are specified, each observation's contribution to its own
group's empirical CDF is weighted by {it:w}/sum({it:w}), the observation's
weight divided by the sum of weights in its group, in place of the
unweighted contribution 1/{it:n}. The pooled empirical CDF is
likewise the weighted average of the group empirical CDFs, weighted by
each group's total weight. In addition, the
variance-standardization term's sample size is replaced by the total Kish
(1965) effective sample size - the sum of each group's own effective
sample size, where a group's effective sample size is the square of the
sum of its weights divided by the sum of its squared weights. This reduces
exactly to the raw combined sample size, and the A^2 statistic reduces
exactly to the ordinary (unweighted) A^2 statistic, when no weight is
specified.

{pstd}
Additionally, when weights are specified, each observation's weight stays
fixed to that observation throughout the permutation procedure - only
group labels are reshuffled. This treats the weight as a fixed, given
attribute of the observation, regardless of how it was generated (e.g.,
inverse-probability weights under any estimand, entropy balancing weights,
or survey weights), and the test reduces exactly to the unweighted case
when no weight is specified.



{title:Options}

{p 6 8 2}
{opth "by(varlist:groupvar)"} is required. It specifies a variable that
identifies the {it:k} groups, where {it:k} >= 2. It may be numeric or
string.

{p 6 8 2}
{opt r:eps(#)} specifies the number of random permutations for the test;
the default is {opt reps(1000)}.

{p 6 8 2}
{opt seed(#)} sets the random-number seed for reproducible results.

{p 6 8 2}
{opt p:ower(#)} specifies the exponent applied to the standardized
per-point distance in the A^2 statistic calculation; the default is
{opt power(2)}, which gives the standard Scholz-Stephens A^2 statistic
with quadratic weighting. Other values modify sensitivity:
{opt power(1)} linear weighting (less sensitive to large differences),
{opt power(3+)} increased sensitivity to tail differences.

{p 6 8 2}
{opt dots} displays a progress dot for each permutation replicate, with a
running count every 50; the default is to display no dots.

{p 6 8 2}
{opt graph} plots the (weighted) empirical CDFs of the {it:k} groups as
step functions, together with the pooled empirical CDF Sbar(x), with the
cumulative A^2 contribution across {it:varname} shown in a second panel
below.

{p 6 8 2}
{opt post:hoc} additionally reports pairwise comparisons between every pair
of groups, with Bonferroni, Sidak, Holm, and FDR-adjusted p-values.



{title:Examples}

{pstd}Set-up{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}{p_end}
{phang2}{cmd:. tab msmoke}{p_end}

{pstd}{opt adtest} across the 4 levels of {cmd:msmoke} (0, 1-5, 6-10, 11+ cigarettes/day), using defaults{p_end}
{phang2}{cmd:. adtest mage, by(msmoke)}{p_end}

{dlgtab:Binary treatment}

{pstd}{opt adtest} on {cmd:mage} using inverse-probability weights built
from a binary treatment model ({cmd:mbsmoke}: smoker vs. non-smoker){p_end}
{phang2}{cmd:. logit mbsmoke mmarried c.mage##c.mage fbaby medu}{p_end}
{phang2}{cmd:. predict pscore, pr}{p_end}
{phang2}{cmd:. gen iptw = cond(mbsmoke, 1/pscore, 1/(1-pscore))}{p_end}
{phang2}{cmd:. adtest mage [pweight=iptw], by(msmoke) reps(2000) seed(12345)}{p_end}

{pstd}change power to linear weighting{p_end}
{phang2}{cmd:. adtest mage [pweight=iptw], by(msmoke) reps(2000) seed(12345) power(1)}{p_end}

{pstd}add the diagnostic graph, with progress dots{p_end}
{phang2}{cmd:. adtest mage [pweight=iptw], by(msmoke) reps(2000) seed(12345) dots graph}{p_end}

{pstd}add post-hoc pairwise comparisons across all 6 group pairs{p_end}
{phang2}{cmd:. adtest mage [pweight=iptw], by(msmoke) reps(2000) seed(12345) posthoc}{p_end}

{dlgtab:Multivalued treatment}

{pstd}{opt adtest} on {cmd:mage} using inverse-probability weights built
from a multivalued (generalized propensity score) treatment model across
all 4 levels of {cmd:msmoke}, rather than the binary {cmd:mbsmoke} model
used above{p_end}
{phang2}{cmd:. mlogit msmoke i.(mmarried fbaby) mage c.mage#c.mage medu c.medu#c.medu c.mage#c.medu, base(0)}{p_end}
{phang2}{cmd:. predict double (ps1 ps2 ps3 ps4), pr}{p_end}
{phang2}{cmd:. gen iptw2 = 1/ps1 if msmoke==0}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps2 if msmoke==1}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps3 if msmoke==2}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps4 if msmoke==3}{p_end}
{phang2}{cmd:. adtest mage [pweight=iptw2], by(msmoke) posthoc}{p_end}



{title:Stored results}

{pstd}
{cmd:adtest} stores the following in {cmd:r()}:

{synoptset 14 tabbed}{...}
{p2col 5 14 16 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}observed (weighted) test statistic (AD if {it:k}=2, A^2 if {it:k}>2){p_end}
{synopt:{cmd:r(p)}}permutation p-value{p_end}
{synopt:{cmd:r(reps)}}number of permutations performed{p_end}
{synopt:{cmd:r(power)}}power parameter specified{p_end}
{synopt:{cmd:r(k)}}number of groups{p_end}
{synopt:{cmd:r(npairs)}}number of pairwise comparisons (if {opt post:hoc} specified){p_end}
{p2colreset}{...}

{synoptset 14 tabbed}{...}
{p2col 5 14 16 2: Macros}{p_end}
{synopt:{cmd:r(by)}}the group variable{p_end}
{synopt:{cmd:r(statlabel)}}label of the statistic actually computed ("AD" if {it:k}=2, "A2" if {it:k}>2){p_end}
{p2colreset}{...}

{synoptset 14 tabbed}{...}
{p2col 5 14 16 2: Matrices}{p_end}
{synopt:{cmd:r(pairwise)}}pairwise AD statistics, raw p-values, and Bonferroni/Sidak/Holm/FDR
adjusted p-values (if {opt post:hoc} specified){p_end}
{p2colreset}{...}



{title:References}

{phang}
Anderson, T. W., and D. A. Darling. 1952.
Asymptotic theory of certain "goodness-of-fit" criteria based on stochastic processes.
{it:Annals of Mathematical Statistics}
23: 193-212.

{phang}
Benjamini, Y., and Y. Hochberg. 1995.
Controlling the false discovery rate: a practical and powerful approach
to multiple testing.
{it:Journal of the Royal Statistical Society, Series B}
57: 289-300.

{phang}
Holm, S. 1979.
A simple sequentially rejective multiple test procedure.
{it:Scandinavian Journal of Statistics}
6: 65-70.

{phang}
Kish, L. 1965. {it:Survey Sampling}. New York: John Wiley & Sons.

{phang}
Linden, A. 2026.
Weighted extensions of the Kolmogorov–Smirnov,
Cramer–von Mises, and Anderson–Darling tests for
assessing covariate balance. Preprint
https://arxiv.org/abs/2607.21782

{phang}
Linden, A. 2026.
Weighted {it:k}-Sample Kolmogorov–Smirnov, Cramer–von Mises, and 
Anderson–Darling tests for assessing covariate balance. Preprint
https://arxiv.org/abs/2608.02929

{phang}
Pettitt, A. N. 1976.
A two-sample Anderson-Darling rank statistic.
{it:Biometrika}
63: 161-168.

{phang}
Scholz, F. W., and M. A. Stephens. 1987.
K-sample Anderson-Darling tests.
{it:Journal of the American Statistical Association}
82: 918-924.

{phang}
Sidak, Z. 1967.
Rectangular confidence regions for the means of multivariate normal
distributions.
{it:Journal of the American Statistical Association}
62: 626-633.



{title:Citation of {cmd:adtest}}

{p 4 8 2}{cmd:adtest} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2026). ADTEST: Stata module to perform a k-sample Anderson-Darling equality-of-distributions test. Statistical Software Components S459559, Boston College Department of
Economics.



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} {helpb kstest} (if installed), {helpb cvmtest} (if installed), {helpb wasstest} (if installed),  {helpb ksmirnov}  {p_end}
