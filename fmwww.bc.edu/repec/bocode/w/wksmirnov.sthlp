{smcl}
{* *! version 1.0.0	10jul2026}{...}

{title:Title}

{p2colset 5 19 20 2}{...}
{p2col:{bf:wksmirnov} {hline 2}}Weighted two-sample Kolmogorov-Smirnov equality-of-distributions test{p_end}
{p2colreset}{...}



{title:Syntax}

{p 8 17 2}
{cmd:wksmirnov} {it:varname} {ifin} {weight} {cmd:,} {cmdab:by:(}{it:groupvar}{cmd:)} [{it:options}]


{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt by(groupvar)}}variable identifying the two groups to compare; required{p_end}
{synopt:{opt r:eps(#)}}perform # Monte Carlo permutations; default is {cmd:reps(0)}, i.e. skipped{p_end}
{synopt:{opt seed(#)}}set random-number seed to #{p_end}
{synopt:{opt nodo:ts}}suppress permutation dots{p_end}
{synopt:{opt gr:aph}}plots the weighted empirical CDFs of the two groups{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see
{help weight}.{p_end}



{title:Description}

{pstd}
{cmd:wksmirnov} computes a weighted two-sample Kolmogorov-Smirnov test of the equality of distributions. 
This is the balance diagnostic used by the R package {cmd:twang} (Toolkit for Weighting and Analysis of 
Nonequivalent Groups) to assess whether propensity-score weighting has equalized the distribution
of a covariate between a treatment group and a comparison group, and to drive its generalized boosted regression 
stopping rules. When weights are not specified, {cmd:wksmirnov} produces the same results as {helpb ksmirnov}.



{title:Options}

{phang}
{opt by(groupvar)} identifies the two comparison groups. {it:groupvar} must
take exactly two distinct nonmissing values in the estimation sample.

{phang}
{opt reps(#)} specifies the number of random permutations to perform.
{it:#} = 0 (the default) skips it.

{phang}
{opt seed(#)} sets the random-number seed; see {helpb set seed}.

{phang}
{opt nodots} suppresses display of the permutation dots.

{phang}
{opt graph} produces a step-function plot of the two weighted empirical
CDFs.



{title:Remarks}

{pstd}
Two p-values are available:

{phang}
1. {bf:Analytic approximation}. The
two-sample Kolmogorov asymptotic null distribution is evaluated using Kish's
(1965) effective sample size in each group g (g = 1 or 0),

{pmore}
ne_g = (sum of w_g)^2 / sum(w_g^2),

{pmore}
combined as en = (ne_1 * ne_0) / (ne_1 + ne_0), with the Stephens (1970)
small-sample correction

{pmore}
lambda = ( sqrt(en) + 0.12 + 0.11/sqrt(en) ) * D,

{pmore}
and p is twice the alternating sum, over k = 1, 2, 3, ..., of the terms

{pmore}
(-1)^(k-1) * exp(-2 * k^2 * lambda^2)

{pmore}
(the standard Kolmogorov tail series).

{phang}
2. {bf:Permutation p-value}. Weights are
rescaled within each group so the treatment group's weights sum to its own
Kish effective N (ne_1) and the comparison group's sum to its Kish
effective N (ne_0), then pooled and normalized; each of {it:#} replicates
draws {bf:trunc(ne_1 + ne_0)} units with replacement from the
full pooled sample using those rescaled weights as draw probabilities,
labels the first floor(ne_1) draws "Group1" and the rest "Group0"
purely by position (not by each draw's original group), and computes an
unweighted KS statistic on that resampled, relabeled draw. The reported
p-value is the raw proportion of replicates whose resampled KS is at least
the observed D.



{title:Stored results}

{pstd}
{cmd:wksmirnov} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(D)}}KS statistic{p_end}
{synopt:{cmd:r(p)}}analytic p-value{p_end}
{synopt:{cmd:r(p_perm)}}permutation p-value using twang's resampling method (if
{opt reps(#)} > 0){p_end}
{synopt:{cmd:r(n_reps)}}number of permutation replicates used{p_end}
{synopt:{cmd:r(N1)}, {cmd:r(N0)}}unweighted N in each group{p_end}
{synopt:{cmd:r(effN1)}, {cmd:r(effN0)}}Kish effective N in each group{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(varname)}}the variable tested{p_end}
{synopt:{cmd:r(group1)}, {cmd:r(group0)}}the two levels of {it:groupvar}{p_end}
{p2colreset}{...}



{title:Examples}

{pstd}
Load example data{p_end}
{p 4 8 2}{cmd:. webuse cattaneo2, clear}{p_end}

{pstd}Estimate propensity score for {cmd:mbsmoke} as the treatment, and generate inverse probability of treatment weights (IPTW) {p_end}
{p 4 8 2}{cmd:. logit mbsmoke mmarried c.mage##c.mage fbaby medu}{p_end}
{p 4 8 2}{cmd:. predict pscore, pr}{p_end}
{p 4 8 2}{cmd:. gen iptw = cond(mbsmoke, 1/pscore, 1/(1-pscore))}{p_end}


{pstd}Run {cmd:wksmirnov} on unweighted {cmd:mage} and compute analytic p-values only {p_end}
{phang}{cmd:. wksmirnov mage, by(mbsmoke)}{p_end}

{pstd}Now run {cmd:wksmirnov} on {cmd:mage} using weights and compute permuted p-values {p_end}
{phang}{cmd:. wksmirnov mage [pweight=iptw], by(mbsmoke) reps(1000) seed(12345)}{p_end}

{pstd}Same as above but specify that a graph also be produced {p_end}
{phang}{cmd:. wksmirnov mage [pweight=iptw], by(mbsmoke) reps(1000) seed(12345) graph}{p_end}



{title:References}

{phang}
Kish, L. 1965. {it:Survey Sampling}. New York: John Wiley & Sons.

{phang}
Ridgeway, G., D.F. McCaffrey, A. Morral, L. Burgette, and B.A. Griffin.
Toolkit for Weighting and Analysis of Nonequivalent Groups: A guide to the
twang package.
{browse "https://cran.r-project.org/web/packages/twang/vignettes/twang.pdf"}

{phang}
Stephens, M.A. 1970. Use of the Kolmogorov-Smirnov, Cramer-von Mises and
Related Statistics Without Extensive Tables. 
{it:Journal of the Royal Statistical Society, Series B}
32(1): 115-122.



{title:Author}

{phang} Ariel Linden {p_end}
{phang} Linden Consulting Group, LLC {p_end}
{phang} alinden@lindenconsulting.org {p_end}



{title:Citation of {cmd:wksmirnov}}

{p 4 8 2}{cmd:wksmirnov} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2026. WKSMIRNOV: Stata module to perform a weighted two-sample Kolmogorov-Smirnov equality-of-distributions test. 
Statistical Software Components Sxxxxxx, Boston College Department of Economics.{p_end}



{title:Also see}

{psee}
{helpb ksmirnov} {p_end}
