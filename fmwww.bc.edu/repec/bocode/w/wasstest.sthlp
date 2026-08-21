{smcl}
{* *! version 2.0.0  04aug2026}{...}

{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{hi:wasstest} {hline 2}} {it:k}-sample Wasserstein distance equality-of-distributions test {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:wasstest}
{varname} {ifin} {weight} {cmd:,} {opth "by(varlist:groupvar)"}
[{cmd:,}
{opt r:eps(#)}
{opt seed(#)}
{opt p:ower(#)}
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
{synopt :{opt p:ower(#)}}specify the exponent for the Wasserstein statistic; default is {opt power(1)}{p_end}
{synopt :{opt gr:aph}}plot the empirical CDFs of the {it:k} groups against the pooled empirical CDF, with the cumulative Wasserstein contribution below{p_end}
{synopt :{opt post:hoc}}also report pairwise comparisons between every pair of groups, with Bonferroni, Sidak, Holm, and FDR adjusted p-values{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt Required}{p_end}
{p 4 6 2}
{cmd:aweight}s, {cmd:pweight}s, and {cmd:iweight}s are
allowed; see {help weight}.{p_end}



{title:Description}

{pstd}
{cmd:wasstest} performs a (optionally weighted) {it:k}-sample Wasserstein
distance permutation test to assess whether {it:k} >= 2 samples come from
the same distribution. It is the {it:k}-sample generalization of the
two-sample Wasserstein test (see Ramdas et al. 2017; Villani 2009).
When {it:k} > 2, there is no single pairwise comparison to make, so wasstest instead
compares each group's empirical CDF to the (weighted) pooled empirical CDF of all groups combined.



{title:Remarks}

{pstd}
When weights are specified, each observation's contribution to its own
group's empirical CDF is weighted by {it:w}/sum({it:w}), the observation's
weight divided by the sum of weights in its group, in place of the
unweighted contribution 1/{it:n}. The pooled empirical CDF is
likewise the weighted average of the group empirical CDFs, weighted by
each group's total weight. The V statistic is then computed from these
weighted step functions exactly as in the unweighted case, and reduces to
the ordinary (unweighted) statistic when no weight is specified.

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
{opt p:ower(#)} specifies the exponent for the Wasserstein statistic
calculation; the default is {opt power(1)}, which gives the standard
Wasserstein distance (Earth Mover's Distance), measuring the minimum
"work" to transform one distribution into another. {opt power(>1)} gives
more weight to large vertical discrepancies between distributions.
{opt power(<1)} gives more balanced weighting, reducing the relative
importance of large discrepancies.

{p 6 8 2}
{opt graph} plots the (weighted) empirical CDFs of the {it:k} groups as
step functions, together with the pooled empirical CDF, with the
cumulative Wasserstein contribution across {it:varname} shown in a second
panel below. Because the Wasserstein statistic accumulates as an area
between curves rather than peaking at a single point, this diagnostic
shows where that area accumulates across the distribution, analogous to
the diagnostic panel in {helpb cvmtestk} and {helpb adtestk}.

{p 6 8 2}
{opt post:hoc} additionally reports pairwise comparisons between every pair
of groups, with Bonferroni, Sidak, Holm, and FDR-adjusted p-values.



{title:Examples}

{pstd}Set-up{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}{p_end}
{phang2}{cmd:. tab msmoke}{p_end}

{pstd}{opt wasstest} across the 4 levels of {cmd:msmoke} (0, 1-5, 6-10, 11+ cigarettes/day), using defaults{p_end}
{phang2}{cmd:. wasstest mage, by(msmoke)}{p_end}

{dlgtab:Binary treatment}

{pstd}{opt wasstest} on {cmd:mage} using inverse-probability weights built
from a binary treatment model ({cmd:mbsmoke}: smoker vs. non-smoker){p_end}
{phang2}{cmd:. logit mbsmoke mmarried c.mage##c.mage fbaby medu}{p_end}
{phang2}{cmd:. predict pscore, pr}{p_end}
{phang2}{cmd:. gen iptw = cond(mbsmoke, 1/pscore, 1/(1-pscore))}{p_end}
{phang2}{cmd:. wasstest mage [pweight=iptw], by(msmoke) reps(2000) seed(12345)}{p_end}

{pstd}add the diagnostic graph, and post-hoc pairwise comparisons{p_end}
{phang2}{cmd:. wasstest mage [pweight=iptw], by(msmoke) reps(2000) seed(12345) graph posthoc}{p_end}

{dlgtab:Multivalued treatment}

{pstd}{opt wasstest} on {cmd:mage} using inverse-probability weights built
from a multivalued (generalized propensity score) treatment model across
all 4 levels of {cmd:msmoke}, rather than the binary {cmd:mbsmoke} model
used above{p_end}
{phang2}{cmd:. mlogit msmoke i.(mmarried fbaby) mage c.mage#c.mage medu c.medu#c.medu c.mage#c.medu, base(0)}{p_end}
{phang2}{cmd:. predict double (ps1 ps2 ps3 ps4), pr}{p_end}
{phang2}{cmd:. gen iptw2 = 1/ps1 if msmoke==0}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps2 if msmoke==1}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps3 if msmoke==2}{p_end}
{phang2}{cmd:. replace iptw2 = 1/ps4 if msmoke==3}{p_end}
{phang2}{cmd:. wasstest mage [pweight=iptw2], by(msmoke) posthoc}{p_end}



{title:Stored results}

{pstd}
{cmd:wasstest} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 14 16 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}observed (weighted) test statistic (W if {it:k}=2, V if {it:k}>2){p_end}
{synopt:{cmd:r(p)}}permutation p-value{p_end}
{synopt:{cmd:r(reps)}}number of permutations performed{p_end}
{synopt:{cmd:r(power)}}power parameter specified{p_end}
{synopt:{cmd:r(k)}}number of groups{p_end}
{synopt:{cmd:r(npairs)}}number of pairwise comparisons (if {opt post:hoc} specified){p_end}
{p2colreset}{...}

{synoptset 15 tabbed}{...}
{p2col 5 14 16 2: Macros}{p_end}
{synopt:{cmd:r(by)}}the group variable{p_end}
{synopt:{cmd:r(statlabel)}}label of the statistic actually computed ("W" if {it:k}=2, "V" if {it:k}>2){p_end}
{p2colreset}{...}

{synoptset 15 tabbed}{...}
{p2col 5 14 16 2: Matrices}{p_end}
{synopt:{cmd:r(pairwise)}}pairwise Wasserstein statistics, raw p-values, and Bonferroni/Sidak/Holm/FDR
adjusted p-values (if {opt post:hoc} specified){p_end}
{p2colreset}{...}



{title:References}

{phang}
Kiefer, J. 1959.
K-sample analogues of the Kolmogorov-Smirnov and Cramer-v. Mises tests.
{it:Annals of Mathematical Statistics}
30(2): 420-447.

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
Ramdas, A., Garcia, N., and Cuturi, M. 2017.
On Wasserstein two-sample testing and related families of nonparametric tests.
{it:Entropy}
19: 47.

{phang}
Scholz, F. W., and M. A. Stephens. 1987.
K-sample Anderson-Darling tests.
{it:Journal of the American Statistical Association}
82: 918-924.

{phang}
Villani, C. 2009.
{it:Optimal Transport: Old and New}.
Springer.



{title:Citation of {cmd:wasstest}}

{p 4 8 2}{cmd:wasstest} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2026). WASSTEST: Stata module to perform a {it:k}-sample Wasserstein distance equality-of-distributions test. Statistical Software Components s459557, Boston College Department
of Economics.



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} {helpb kstest} (if installed), {helpb cvmtest} (if installed), {helpb adtest} (if installed), {helpb ksmirnov} {p_end}
