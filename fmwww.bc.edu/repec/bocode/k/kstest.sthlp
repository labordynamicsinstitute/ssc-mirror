{smcl}
{* *! version 1.0.0  12jul2026}{...}

{title:Title}

{p2colset 5 15 16 2}{...}
{p2col:{hi:kstest} {hline 2}}Weighted two-sample Kolmogorov-Smirnov equality-of-distributions test {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:kstest}
{varname} {ifin} {weight} {cmd:,} {opth "by(varlist:groupvar)"}
[{cmd:,}
{opt r:eps(#)}
{opt seed(#)}
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
{synopt :{opt do:ts}}display permutation progress dots; default is off{p_end}
{synopt :{opt gr:aph}}plot the empirical CDFs of the two groups, with the D statistic marked{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt Required}{p_end}
{p 4 6 2}
{cmd:aweight}s, {cmd:pweight}s, and {cmd:iweight}s are
allowed; see {help weight}.{p_end}



{title:Description}

{pstd}
{cmd:kstest} performs a (optionally weighted) two-sample Kolmogorov-Smirnov (KS)
permutation test to assess whether two samples come from the same distribution.
The KS statistic is the single largest absolute difference between the two
empirical cumulative distribution functions (ECDFs), making it most sensitive
to a discrepancy that is large and concentrated at one location, and less
sensitive to differences spread across the distribution or concentrated in
the tails (see {helpb adtest} and {helpb cvmtest} for alternative tests
better suited to those cases). The permutation test provides a valid p-value
by comparing the observed statistic to its distribution under random
reassignment of group labels.



{title:Remarks}

{pstd}
When weights are specified, each observation's contribution to its own group's 
empirical CDF is weighted by {it:w}/sum({it:w}), the observation's weight divided 
by the sum of weights in its group, in place of the unweighted contribution 
1/{it:n}. The KS statistic is then the maximum absolute difference between these two
weighted step functions, exactly as in the unweighted case, and reduces to
the ordinary (unweighted) KS statistic when no weight is specified.

{pstd}
Additionally, when weights are specified, each observation's weight stays fixed to that
observation throughout the permutation procedure --- only group labels are
reshuffled. This treats the weight as a fixed, given attribute of the
observation, regardless of how it was generated (e.g., inverse-probability
weights under any estimand, entropy balancing weights, or survey weights),
and the test reduces exactly to the unweighted case when no weight is
specified.



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
{opt dots} displays a progress dot for each permutation replicate, with a
running count every 50; the default is to display no dots.

{p 6 8 2}
{opt graph} plots the (weighted) empirical CDFs of the two groups as step
functions, with the location of the D statistic marked directly on the plot.



{title:Examples}

{pstd}Set-up{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}{p_end}
{phang2}{cmd:. logit mbsmoke mmarried c.mage##c.mage fbaby medu}{p_end}
{phang2}{cmd:. predict pscore, pr}{p_end}
{phang2}{cmd:. gen iptw = cond(mbsmoke, 1/pscore, 1/(1-pscore))}{p_end}

{pstd}{opt kstest} on unweighted {cmd:mage}, using defaults{p_end}
{phang2}{cmd:. kstest mage, by(mbsmoke)}{p_end}

{pstd}{opt kstest} on {cmd:mage} using weights{p_end}
{phang2}{cmd:. kstest mage [pweight=iptw], by(mbsmoke) reps(2000) seed(12345)}{p_end}

{pstd}add the diagnostic graph, with progress dots{p_end}
{phang2}{cmd:. kstest mage [pweight=iptw], by(mbsmoke) reps(2000) seed(12345) dots graph}{p_end}



{title:Stored results}

{pstd}
{cmd:kstest} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 14 16 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}observed (weighted) D statistic{p_end}
{synopt:{cmd:r(p)}}permutation p-value{p_end}
{synopt:{cmd:r(reps)}}number of permutations performed{p_end}
{p2colreset}{...}

{synoptset 12 tabbed}{...}
{p2col 5 14 16 2: Macros}{p_end}
{synopt:{cmd:r(group1)}}name of group 1{p_end}
{synopt:{cmd:r(group2)}}name of group 2{p_end}
{synopt:{cmd:r(by)}}the group variable{p_end}
{p2colreset}{...}



{title:References}

{phang}
Kolmogorov, A. 1933.
Sulla determinazione empirica di una legge di distribuzione.
{it:Giornale dell'Istituto Italiano degli Attuari}
4: 83-91.

{phang}
Linden, A. 2026.
Weighted extensions of the Kolmogorov–Smirnov,
Cramer–von Mises, and Anderson–Darling tests for
assessing covariate balance. Preprint
{it:arXiv}

{phang}
Smirnov, N. 1948.
Table for estimating the goodness of fit of empirical distributions.
{it:Annals of Mathematical Statistics}
19: 279-281.



{title:Citation of {cmd:kstest}}

{p 4 8 2}{cmd:kstest} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2026). KSTEST: Stata module to perform a weighted two-sample Kolmogorov-Smirnov equality-of-distributions test. Statistical Software Components,
Boston College Department of Economics.



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} {helpb ksmirnov}, {helpb adtest} (if installed), {helpb cvmtest} (if installed), {helpb kuipertest} (if installed), {helpb wasstest} (if installed), {helpb escftest} (if installed),
{helpb distcomp} (if installed) {p_end}

