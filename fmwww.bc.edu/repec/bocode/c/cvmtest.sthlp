{smcl}
{* *! version 2.0.0  12jul2026}{...}

{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{hi:cvmtest} {hline 2}}Two-sample Cramer-von Mises equality-of-distributions test {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cvmtest}
{varname} {ifin} {weight} {cmd:,} {opth "by(varlist:groupvar)"}
[{cmd:,}
{opt r:eps(#)}
{opt seed(#)}
{opt p:ower(#)}
{opt do:ts}
{opt gr:aph}]

{pstd}
{it:{help varlist:groupvar}} must take on
two distinct values. The distribution of {it:varname} for the first value of
{it:groupvar} is compared with that of the second value.



{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth "by(varlist:groupvar)"}}specify a binary variable that identifies the two groups{p_end}
{synopt :{opt r:eps(#)}}perform # Monte Carlo permutations; default is {opt reps(1000)}{p_end}
{synopt :{opt seed(#)}}set random-number seed to #{p_end}
{synopt :{opt p:ower(#)}}specify the exponent for the CVM statistic; default is {opt power(2)}{p_end}
{synopt :{opt do:ts}}display permutation progress dots; default is off{p_end}
{synopt :{opt gr:aph}}plot the empirical CDFs of the two groups, with the cumulative CVM contribution below{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt Required}{p_end}
{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are
allowed; see {help weight}.{p_end}



{title:Description}

{pstd}
{cmd:cvmtest} performs a (optionally weighted) two-sample Cramer-von Mises
(CVM) permutation test to assess whether two samples come from the same
distribution. The CVM statistic sums the squared discrepancy between the
two empirical cumulative distribution functions (ECDFs) across every
distinct value in the combined sample, with no variance standardization,
making it best suited to detecting a discrepancy that is diffuse across the
distribution, and less sensitive than Kolmogorov-Smirnov ({helpb kstest}) to 
a single large, localized discrepancy or than Anderson-Darling ({helpb adtest}) 
to a discrepancy concentrated in the tails. The permutation test provides 
a valid p-value by comparing the observed statistic to its distribution 
under random reassignment of group labels.



{title:Remarks}

{pstd}
When weights are specified, each observation's contribution to its own
group's empirical CDF is weighted by {it:w}/sum({it:w}), the observation's
weight divided by the sum of weights in its group, in place of the
unweighted contribution 1/{it:n}. The CVM statistic is then the sum of the
squared differences between these two weighted step functions at every
distinct value, exactly as in the unweighted case, and reduces to the
ordinary (unweighted) CVM statistic when no weight is specified. Unlike
{helpb adtest}, CVM has no variance-standardization term and no tie
multiplier to also generalize; the weighted-contribution substitution is
the only change required.

{pstd}
Additionally, when weights are specified, each observation's weight stays
fixed to that observation throughout the permutation procedure --- only
group labels are reshuffled. This treats the weight as a fixed, given
attribute of the observation, regardless of how it was generated (e.g.,
inverse-probability weights under any estimand, entropy balancing weights,
or survey weights), and the test reduces exactly to the unweighted case
when no weight is specified.



{title:Options}

{p 6 8 2}
{opth "by(varlist:groupvar)"} is required. It specifies a binary variable
that identifies the two groups.

{p 6 8 2}
{opt r:eps(#)} specifies the number of random permutations for the test;
the default is {opt reps(1000)}.

{p 6 8 2}
{opt seed(#)} sets the random-number seed for reproducible results.

{p 6 8 2}
{opt p:ower(#)} specifies the exponent for the CVM statistic calculation;
the default is {opt power(2)}, which gives the standard CVM statistic with
quadratic weighting. Other values modify sensitivity:
{opt power(1)} linear weighting (less sensitive to large differences),
{opt power(3+)} increased sensitivity to large distributional differences.

{p 6 8 2}
{opt dots} displays a progress dot for each permutation replicate, with a
running count every 50; the default is to display no dots.

{p 6 8 2}
{opt graph} plots the (weighted) empirical CDFs of the two groups as step
functions, with the cumulative CVM contribution across {it:varname} shown
in a second panel below.



{title:Examples}

{pstd}Set-up{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}{p_end}
{phang2}{cmd:. logit mbsmoke mmarried c.mage##c.mage fbaby medu}{p_end}
{phang2}{cmd:. predict pscore, pr}{p_end}
{phang2}{cmd:. gen iptw = cond(mbsmoke, 1/pscore, 1/(1-pscore))}{p_end}

{pstd}{opt cvmtest} on unweighted {cmd:mage}, using defaults{p_end}
{phang2}{cmd:. cvmtest mage, by(mbsmoke)}{p_end}

{pstd}{opt cvmtest} on {cmd:mage} using weights{p_end}
{phang2}{cmd:. cvmtest mage [pweight=iptw], by(mbsmoke) reps(2000) seed(12345)}{p_end}

{pstd}change power to linear weighting{p_end}
{phang2}{cmd:. cvmtest mage [pweight=iptw], by(mbsmoke) reps(2000) seed(12345) power(1)}{p_end}

{pstd}add the diagnostic graph, with progress dots{p_end}
{phang2}{cmd:. cvmtest mage [pweight=iptw], by(mbsmoke) reps(2000) seed(12345) dots graph}{p_end}



{title:Stored results}

{pstd}
{cmd:cvmtest} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 14 16 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}observed (weighted) CVM statistic{p_end}
{synopt:{cmd:r(p)}}permutation p-value{p_end}
{synopt:{cmd:r(reps)}}number of permutations performed{p_end}
{synopt:{cmd:r(power)}}power parameter specified{p_end}
{p2colreset}{...}

{synoptset 12 tabbed}{...}
{p2col 5 14 16 2: Macros}{p_end}
{synopt:{cmd:r(group1)}}name of group 1{p_end}
{synopt:{cmd:r(group2)}}name of group 2{p_end}
{synopt:{cmd:r(by)}}the group variable{p_end}
{p2colreset}{...}



{title:References}

{phang}
Cramer, H. 1928.
On the composition of elementary errors.
{it:Scandinavian Actuarial Journal}
1928(1): 13-74.

{phang}
Dwass, M. 1957.
Modified randomization tests for nonparametric hypotheses.
{it:Annals of Mathematical Statistics}
28: 181-187.

{phang}
Linden, A. 2026.
Weighted extensions of the Kolmogorov–Smirnov,
Cramer–von Mises, and Anderson–Darling tests for
assessing covariate balance. Preprint
{it:arXiv}

{phang}
von Mises, R. 1931.
{it:Wahrscheinlichkeitsrechnung und ihre Anwendung in der Statistik und
theoretischen Physik}. Leipzig: Deuticke.



{title:Citation of {cmd:cvmtest}}

{p 4 8 2}{cmd:cvmtest} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). CVMTEST: Stata module to perform a two-sample Cramer-von Mises equality-of-distributions test.  Statistical Software Components S459558, Boston College Department
of Economics.



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} {helpb ksmirnov}, {helpb kstest} (if installed), {helpb adtest} (if installed), {helpb kuipertest} (if installed), {helpb wasstest} (if installed), {helpb escftest} (if installed),
{helpb distcomp} (if installed) {p_end}
