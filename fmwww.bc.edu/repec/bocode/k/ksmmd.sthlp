{smcl}
{* *! version 0.3  16sep2026}{...}
{vieweralsosee "svylet" "help svylet"}{...}
{vieweralsosee "tsvy" "help tsvy"}{...}
{vieweralsosee "ksmmd (en espanol)" "help ksmmd_es"}{...}
{viewerjumpto "Syntax" "ksmmd##syntax"}{...}
{viewerjumpto "Description" "ksmmd##description"}{...}
{viewerjumpto "Options" "ksmmd##options"}{...}
{viewerjumpto "Remarks" "ksmmd##remarks"}{...}
{viewerjumpto "Examples" "ksmmd##examples"}{...}
{viewerjumpto "Stored results" "ksmmd##results"}{...}
{viewerjumpto "References" "ksmmd##references"}{...}
{viewerjumpto "Author" "ksmmd##author"}{...}
{viewerjumpto "Also see" "ksmmd##also_see"}{...}
{hline}
{title:Title}

{phang}
{bf:ksmmd} {hline 2} Weighted k-sample distributional test combining
Kolmogorov-Smirnov (Kiefer's T) and Maximum Mean Discrepancy (MMD via
Random Fourier Features)

{phang}
{it:Version {bf:0.2} (16sep2026)}{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ksmmd} {it:varname} {ifin}{cmd:,} {cmdab:by:(}{it:groupvar}{cmd:)}
[{it:options}]

{p 8 17 2}
{it:varname} may be weighted with {cmd:[}{help weight:pweight}{cmd:|}{help weight:aweight}{cmd:|}{help weight:iweight}{cmd:]}.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt by:(groupvar)}}variable identifying the {it:k} groups to
compare; required, {it:k} {>=} 2 distinct values, string or numeric{p_end}
{synopt:{opt reps:(#)}}number of permutations for both p-values;
default {cmd:reps(1000)}{p_end}
{synopt:{opt seed(#)}}random-number seed, passed to Stata's {helpb set seed}{p_end}
{synopt:{opt dots}}show a permutation progress dot every replication{p_end}
{synopt:{opt graph}}draw the weighted empirical CDFs by group, plus
the pooled CDF{p_end}
{synopt:{opt posthoc}}pairwise table for both KS and MMD, with
Bonferroni/Sidak/Holm/FDR-adjusted p-values{p_end}

{syntab:MMD (Random Fourier Features)}
{synopt:{opt bw(#)}}RBF kernel bandwidth; default {cmd:bw(-1)} triggers
the median-heuristic estimate (see {help ksmmd##remarks_rff:Remarks})
on a random subsample of up to 2,000 observations{p_end}
{synopt:{opt nf:eatures(#)}}number of random Fourier features (the
approximation's dimension {it:D}); default {cmd:nfeatures(200)}{p_end}
{synopt:{opt mmdtype(string)}}{cmd:vspool} (default) or
{cmd:maxpairwise} -- see {help ksmmd##remarks_mmdtype:Remarks}{p_end}

{syntab:Scope}
{synopt:{opt ksonly}}skip the MMD computation, report only the KS
(Kiefer) statistic{p_end}
{synopt:{opt mmdonly}}skip the KS computation, report only MMD{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ksmmd} tests whether {it:k} {cmd:>=} 2 groups (named by
{opt by()}) come from the same distribution of {it:varname}, computing
{it:two} test statistics from a {bf:single} permutation resample:

{phang2}o a k-sample generalization of the Kolmogorov-Smirnov test
(Kiefer's T -- Kiefer 1959), the same statistic {helpb kstest}
(Ariel Linden, SSC {browse "https://ideas.repec.org/c/boc/bocode/s459801.html":s459801}) computes, but reimplemented here so that {it:varname}
is sorted once (not re-sorted on every permutation) -- see
{help ksmmd##remarks_why:Remarks: why reimplement kstest}.{p_end}
{phang2}o a k-sample generalization of the Maximum Mean Discrepancy
(MMD -- Gretton et al. 2012) with an RBF kernel, approximated via
Random Fourier Features (Rahimi & Recht 2007) so it stays tractable
at survey-sized {it:n} (~10^5), unlike {browse "https://ideas.repec.org/c/boc/bocode/s459820.html":mmd_2s} (Boston College SSC
{cmd:s459820}), which only compares 2 groups with an exact O(N^2)
kernel.{p_end}

{pstd}
Both statistics are weighted (via the passed-through survey/analytic
weight), both are tested by permutation, and {cmd:ksmmd} is
self-contained in Mata -- it does not call {helpb kstest} or
{cmd:mmd_2s}, and does not require {helpb svyset} (it does not use the
sampling design's strata/PSU structure; see
{help ksmmd##remarks_weights:Remarks: weights are not survey design}).

{pstd}
{cmd:ksmmd} is a {bf:standalone} command -- it has no
{cmd:caida()}/{cmd:cruce()} loop of its own the way {helpb tsvy} does.
Run it once per universe you have already restricted with
{cmd:[if]}/{cmd:subpop()}, exactly as you would {helpb kstest}.
Whether/how it gets wired into {cmd:tsvy}'s own {cmd:mmd} option is a
separate, later decision (see {cmd:tsvy.sthlp}, option {cmd:mmd}).


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt by(groupvar)} names the variable identifying the {it:k} groups.
Must have at least 2 distinct values in the analysis sample; string
values are recoded to 1..{it:k} internally (mapped back to their
original labels in the output).

{phang}
{opt reps(#)} is the number of permutation replications used for
{bf:both} the KS and the MMD p-value -- one shared resample, not two
separate ones. Lower it (e.g., {cmd:reps(200)}) for a quick,
exploratory pass; raise it (e.g., {cmd:reps(1000)} or more) for the
result you will report. See
{help ksmmd##remarks_agile:Remarks: agile vs final}.

{phang}
{opt seed(#)} sets the random seed before drawing permutations (and,
if {opt bw()} is not given, before the median-heuristic subsample and
the random Fourier frequencies) -- pass it to get a reproducible run.

{phang}
{opt dots} prints a progress dot per permutation, same convention as
{helpb kstest}.

{phang}
{opt graph} draws the weighted empirical CDFs, one per group plus the
pooled curve (dashed) -- the same style of plot as {cmd:kstest ...,
graph}, saved to a graph named {cmd:ksmmd_ecdf}. It is the natural
visual for the KS statistic; MMD has no native 1-D curve (it lives in
the random-feature space), but the same ECDF is still the relevant
reference for it, since both operate on the same {it:varname}.

{phang}
{opt posthoc} adds, after the omnibus results, one pairwise table per
statistic (KS and MMD) across all {it:k}({it:k}-1)/2 pairs of groups,
each with raw and Bonferroni/Sidak/Holm/FDR-adjusted p-values -- same
layout as {cmd:kstest ..., posthoc}. Each pair re-runs
{opt reps()} permutations restricted to just those two groups.

{dlgtab:MMD (Random Fourier Features)}

{phang}
{opt bw(#)} is the RBF kernel bandwidth. The default,
{cmd:bw(-1)}, triggers the median-heuristic bandwidth (Garreau,
Jitkrittum & Kanagawa 2017) computed on a random subsample of up to
2,000 observations (not the full dataset, for cost reasons -- see
{help ksmmd##remarks_rff:Remarks}). Pass a positive value to fix it
yourself, e.g. for comparability across repeated calls.

{phang}
{opt nfeatures(#)} is {it:D}, the number of random Fourier features
used to approximate the RBF kernel. Default {cmd:nfeatures(200)}.
Larger {it:D} tightens the MMD approximation (expected error shrinks
like {it:D}^-0.5 -- Sutherland & Schneider 2015) at a proportional
compute cost; see {help ksmmd##remarks_agile:Remarks: agile vs final}.

{phang}
{opt mmdtype(string)} selects the k-sample combination rule for MMD:
{cmd:vspool} (default) or {cmd:maxpairwise}. See
{help ksmmd##remarks_mmdtype:Remarks} for the exact formulas, the
citations, and why a third option from an earlier version
({cmd:pairwise}) was removed as mathematically redundant with
{cmd:vspool}.

{dlgtab:Scope}

{phang}
{opt ksonly} skips the MMD computation entirely -- useful for a fast
pass when only the (cheaper, exact) KS result is needed, or while
exploring before deciding on {opt bw()}/{opt nfeatures()}.

{phang}
{opt mmdonly} skips the KS computation, reporting only MMD.
{opt ksonly} and {opt mmdonly} are mutually exclusive.


{marker remarks}{...}
{title:Remarks and examples}

{pstd}
Remarks are presented under the following headings:

{phang2}{help ksmmd##remarks_why:Why reimplement kstest instead of calling it}{p_end}
{phang2}{help ksmmd##remarks_mmdtype:mmdtype() -- vspool vs. maxpairwise}{p_end}
{phang2}{help ksmmd##remarks_rff:MMD via Random Fourier Features}{p_end}
{phang2}{help ksmmd##remarks_weights:Weights are not a survey design}{p_end}
{phang2}{help ksmmd##remarks_kmd:KMD was evaluated and excluded}{p_end}
{phang2}{help ksmmd##remarks_agile:Agile vs. final: reps() and nfeatures()}{p_end}

{marker remarks_why}{...}
{pstd}{bf:Why reimplement kstest instead of calling it}

{pstd}
{cmd:kstest} (Ariel Linden, SSC {cmd:s459801}) already computes
Kiefer's T by permutation, but its Mata engine re-sorts {it:varname}
inside every one of the {opt reps()} replications (its group-label
permutation is applied {it:before} the sort, not after). For a single
2-or-more-sample test that is a minor cost. For {cmd:ksmmd}, KS and
MMD share the exact same permutation draws, and MMD's cost already
scales with {it:reps()}*{it:N}*{opt nfeatures()} -- re-sorting {it:N}
values on top of that, {it:reps()} times, is avoidable: sorting
{it:varname} {bf:once} and permuting only the group label attached to
each sorted position is mathematically equivalent (a permutation of a
fixed sorted sequence's labels), and removes an O(N log N) factor from
every replication.

{marker remarks_mmdtype}{...}
{pstd}{bf:mmdtype() -- vspool vs. maxpairwise}

{pstd}
{cmd:mmdtype(vspool)} (default):

{p 8 8 2}T_MMD = sum_j Wsum_j * ||mu_j - mu_pool||^2{p_end}

{pstd}
the same "each group against the pool" pattern Kiefer's T uses to
generalize the 2-sample D statistic to k samples. This is
{bf:algebraically identical} (verified directly, a Huygens/ANOVA-type
decomposition in Hilbert space:
sum_j n_j||mu_j-mu_pool||^2 = (1/N)*sum_{{c i<j}} n_i n_j ||mu_i-mu_j||^2)
to the pairwise-weighted RBF-kernel k-sample MMD of Ong, Chen, Zhu &
Zhang (2023, {it:Mathematics} 11(20)) and, in the general unequal-size
k-sample framework, Zhang, Guo & Zhou (2022, {it:J. Econometrics}) --
the same statistic up to a positive constant ({it:Wtot}, the total
weight, which does not depend on the label permutation and therefore
never changes the permutation p-value).

{pstd}
{cmd:mmdtype(maxpairwise)}:

{p 8 8 2}T_MMD = max_{{c k<l}} [Wsum_k*Wsum_l/(Wsum_k+Wsum_l)] * ||mu_k - mu_l||^2{p_end}

{pstd}
Kim (2021, {it:Bernoulli} 27(1)), weighted form for unequal sizes (his
Remark 3.3, adapted here with {cmd:Wsum} in place of {it:n} for
continuous survey weights). Unlike {cmd:vspool} (which averages the
discrepancy across {it:all} groups), {cmd:maxpairwise} is sensitive to
a {it:single} pair of groups differing sharply even when every other
pair is identical -- a genuinely different alternative-hypothesis
profile, not a rescaling of {cmd:vspool}.

{pstd}
An earlier version of this command offered a third option,
{cmd:mmdtype(pairwise)}, computed {it:without} the
{cmd:Wsum_k*Wsum_l/Wtot} weight. Once that weight is added it becomes
{bf:exactly} {cmd:vspool} (not merely proportional -- the identical
number), so it was removed as redundant rather than kept as a third,
illusory alternative.

{marker remarks_rff}{...}
{pstd}{bf:MMD via Random Fourier Features}

{pstd}
An exact RBF-kernel MMD needs the full N x N kernel matrix -- O(N^2),
infeasible once N is in the hundreds of thousands (the exact problem
that made {cmd:mmd_2s} too slow in production for this scenario).
{cmd:ksmmd} instead approximates the kernel with {opt nfeatures()}
random Fourier features (Rahimi & Recht 2007): phi(x) = sqrt(2/D) *
cos(omega*x + b), omega ~ N(0, 1/bw^2), b ~ Uniform(0, 2*pi) --
turning the cost into O(reps * N * D), linear in {it:N}.

{pstd}
The known error bound is on the MMD statistic itself, not just the
kernel (Sutherland & Schneider 2015, Theorem 1):
P(|MMD_RFF - MMD| >= eps) <= 2*exp(-D*eps^2/128), expected absolute
error <= 8*sqrt(2*pi/D) -- halving the expected error requires
{bf:quadrupling} {opt nfeatures()}. Choi & Kim (2024) further show
that with {it:fixed} {it:D}, the RFF-based test's power is not
guaranteed to be consistent -- a low {opt nfeatures()} can lose power
relative to the exact MMD test, which is why {opt nfeatures()} follows
the same agile-then-final logic as {opt reps()} (see
{help ksmmd##remarks_agile:Remarks} below).

{pstd}
{opt bw(-1)} (the default) uses the median-heuristic bandwidth
(Garreau, Jitkrittum & Kanagawa 2017) on a random subsample of up to
2,000 observations, not the full dataset -- computing the exact median
of all pairwise distances is itself O(n^2).

{marker remarks_weights}{...}
{pstd}{bf:Weights are not a survey design}

{pstd}
{cmd:ksmmd} accepts {cmd:[aweight/pweight/iweight]} and uses them
throughout (weighted group means in feature space, weighted ECDF), but
it does {bf:not} use {helpb svyset}'s strata/PSU structure -- same
limitation as {cmd:mmd_2s} and {cmd:kstest}. A search of the indexed
literature (September 2026) found {bf:no} peer-reviewed MMD or
energy-statistics test that treats survey-design (unequal-probability)
weights specifically. What exists is {it:importance weighting} (Bellot
& van der Schaar 2021, UAI, WMMD; Bharti et al. 2023, ICML;
Diesendruck et al. 2018/2019) -- a {bf:different} concept, correcting
selection bias between 2 distributions, not representing a population
via an expansion factor. Inserting {cmd:Wsum} into the plug-in MMD
estimator the way a Horvitz-Thompson mean would is a reasonable
extension, but it has no paper proving its validity under survey
weights specifically -- precisely because that paper does not appear
to exist, the only honest way to trust it is a Type-I-error Monte
Carlo simulation (the same kind already run for {cmd:kstest} in this
package's {cmd:sim/} directory), not a citation. That simulation has now been run for {bf:both} {cmd:mmdtype()}
options: {cmd:vspool} ({cmd:sim/simulacion_ksmmd_mmd_tipo1.py} /
{cmd:resultados_ksmmd_mmd_tipo1.txt}) and {cmd:maxpairwise}
({cmd:sim/simulacion_ksmmd_mmd_maxpairwise_tipo1.py} /
{cmd:resultados_ksmmd_mmd_maxpairwise_tipo1.txt}) -- same 3-scenario
design as the {cmd:kstest} simulation in both cases, worst-case
rejection rate under a true null around 6% (vs. 5% nominal) for
either option, consistent with, and no worse than, {cmd:kstest}'s own
result.

{marker remarks_kmd}{...}
{pstd}{bf:KMD was evaluated and excluded}

{pstd}
A third distributional-dissimilarity family, KMD (Huang & Sen 2024,
{it:JASA} -- "A Kernel Measure of Dissimilarity between M
Distributions"), was read in full and considered for {cmd:ksmmd}.
It was excluded by explicit decision: its published estimator (a
k-nearest-neighbor graph statistic) has {bf:no} weighted version in the
paper, conflicting with the requirement that motivated this whole
command ("respect the survey design or use weights, like kstest").
Building a fast k-NN graph in Mata (without a KD-tree-type structure)
is also a separate performance problem of the same order as the one
Random Fourier Features solves for MMD -- not something to bolt on
"for free" in this version.

{marker remarks_agile}{...}
{pstd}{bf:Agile vs. final: reps() and nfeatures()}

{pstd}
Both {opt reps()} and {opt nfeatures()} trade precision for speed.
For a fast, exploratory pass (deciding whether a difference looks
worth reporting at all), lower both, e.g.
{cmd:reps(200) nfeatures(50)}. For the number you will actually cite,
raise both, e.g. {cmd:reps(1000) nfeatures(500)} or higher -- neither
default is a magic number, they are starting points to tune against
your own N and time budget.


{marker examples}{...}
{title:Examples}

{pstd}
Every example below runs on {cmd:auto.dta}, one of Stata's built-in
datasets -- {cmd:sysuse auto} is enough, no external data needed.

{phang2}{cmd:* Setup}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen byte g = 1 + mod(_n, 3)}{p_end}
{phang2}{cmd:. gen double wgt = 1}{p_end}

{pstd}
{bf:Example 1: unweighted, quick pass.} 3 pseudo-groups, both
statistics, few permutations for speed:{p_end}
{phang2}{cmd:* Example 1: quick unweighted pass}{p_end}
{phang2}{cmd:. ksmmd mpg, by(g) reps(200)}{p_end}

{pstd}
{bf:Example 2: weighted, with graph and posthoc.} Uses {cmd:wgt}
(here constant, standing in for a real analytic/survey weight):{p_end}
{phang2}{cmd:* Example 2: weighted, graph, posthoc}{p_end}
{phang2}{cmd:. ksmmd mpg [aweight=wgt], by(g) reps(500) seed(20260916) ///}{p_end}
{phang2}{cmd:    graph posthoc}{p_end}

{pstd}
{bf:Example 3: maxpairwise instead of vspool}, sensitive to a single
divergent pair of groups:{p_end}
{phang2}{cmd:* Example 3: maxpairwise}{p_end}
{phang2}{cmd:. ksmmd mpg [aweight=wgt], by(g) mmdtype(maxpairwise) ///}{p_end}
{phang2}{cmd:    reps(500)}{p_end}

{pstd}
{bf:Example 4: KS only}, skipping MMD entirely for a fast look:{p_end}
{phang2}{cmd:* Example 4: ksonly}{p_end}
{phang2}{cmd:. ksmmd mpg [aweight=wgt], by(g) ksonly reps(200)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ksmmd} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(T_KS)}}Kiefer's T statistic (missing if {opt mmdonly})}{p_end}
{synopt:{cmd:r(P_KS)}}permutation p-value for T_KS{p_end}
{synopt:{cmd:r(T_MMD)}}MMD statistic, per {opt mmdtype()} (missing if {opt ksonly})}{p_end}
{synopt:{cmd:r(P_MMD)}}permutation p-value for T_MMD{p_end}
{synopt:{cmd:r(reps)}}number of permutations used{p_end}
{synopt:{cmd:r(k)}}number of groups{p_end}
{synopt:{cmd:r(npairs)}}number of pairs in the posthoc table (if {opt posthoc}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(by)}}name of the {opt by()} variable{p_end}
{synopt:{cmd:r(mmdtype)}}{cmd:vspool} or {cmd:maxpairwise}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(pairwise_ks)}}pairwise table for KS (if {opt posthoc}
and not {opt mmdonly}) -- columns
Stat/P_raw/P_bonf/P_sidak/P_holm/P_fdr, one row per pair{p_end}
{synopt:{cmd:r(pairwise_mmd)}}pairwise table for MMD (if {opt posthoc}
and not {opt ksonly}), same column layout{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{pstd}
Kiefer, J. (1959). K-sample analogues of the Kolmogorov-Smirnov and
Cramer-v. Mises tests. {it:Ann. Math. Statist.} 30(2), 420-447.

{pstd}
Gretton, A., Borgwardt, K.M., Rasch, M.J., Scholkopf, B., Smola, A.
(2012). A Kernel Two-Sample Test. {it:JMLR} 13(25), 723-773.

{pstd}
Rahimi, A., Recht, B. (2007). Random Features for Large-Scale Kernel
Machines. {it:NeurIPS} 20.

{pstd}
Sutherland, D.J., Schneider, J. (2015). On the Error of Random Fourier
Features. {it:UAI} 2015.

{pstd}
Ong, C.S., Chen, X., Zhu, D., Zhang, Y. (2023). Testing Equality of
Several Distributions at High Dimensions: A Maximum Mean
Discrepancy-Based Approach. {it:Mathematics} 11(20), 4272.

{pstd}
Zhang, Y., Guo, X., Zhou, W. (2022). Testing equality of several
distributions in separable metric spaces: a maximum mean discrepancy
based approach. {it:J. Econometrics}.

{pstd}
Kim, I. (2021). Comparing a large number of multivariate
distributions. {it:Bernoulli} 27(1), 419-441.

{pstd}
Sejdinovic, D., Sriperumbudur, B., Gretton, A., Fukumizu, K. (2013).
Equivalence of distance-based and RKHS-based statistics in hypothesis
testing. {it:Ann. Statist.} 41(5), 2263-2291.

{pstd}
Rizzo, M.L., Szekely, G.J. (2010). DISCO analysis: a nonparametric
extension of analysis of variance. {it:Ann. Appl. Stat.} 4(2), 1034-1055.

{pstd}
Szekely, G.J., Rizzo, M.L. (2004). Testing for Equal Distributions in
High Dimension. {it:InterStat}, Nov(5).

{pstd}
Rizzo, M.L., Szekely, G.J. (2016). Energy distance. {it:WIREs
Computational Statistics} 8(1), 27-38.

{pstd}
Garreau, D., Jitkrittum, W., Kanagawa, M. (2017). Large sample
analysis of the median heuristic. arXiv:1707.07269.

{pstd}
Choi, S., Kim, I. (2024). Computational-Statistical Trade-off in
Kernel Two-Sample Testing with Random Fourier Features. arXiv:2407.08976.

{pstd}
Huang, Z., Sen, B. (2024). A Kernel Measure of Dissimilarity between M
Distributions. {it:JASA} 119(548), 3020-3032 (evaluated, {bf:not}
incorporated -- see {help ksmmd##remarks_kmd:Remarks}).


{marker author}{...}
{title:Author}

{pstd}
Andres Talavera Cuya. Affiliation stated for identification purposes
only -- this software is not an official product of INEI and INEI
bears no responsibility for it. Distributed under the GNU General
Public License v3 (https://www.gnu.org/licenses/gpl-3.0.txt).

{pstd}
Version 0.2's resampling engine (one permutation at a time) {bf:was}
run against real Stata in the session that produced this file,
including on real production data (N~127,000). Version 0.3 rewrites
that engine to process permutations in vectorized blocks instead of
one at a time (v0.2's speedup over {cmd:mmd_2s} was only ~4-5x in
practice, far short of the ~N/D expected from replacing an O(N^2)
exact kernel with O(N*D) random features); the resulting statistics
follow the same algebra, but the rewrite itself has {bf:not} yet been
run against real Stata (no Stata available in the environment where it
was written) -- see the v0.3 note and the warning near the top of
{cmd:ksmmd.ado} for the validation steps to run before relying on it in
production.

{pstd}
Source: {browse "https://github.com/atalaveracuya/svylet"}. Not (yet)
an SSC package; download {cmd:ksmmd.ado} and this help file into a
directory on your {stata "adopath"}.


{marker also_see}{...}
{title:Also see}

{psee}
Online: {helpb svylet}, {helpb tsvy}, {helpb svy}
{p_end}

{psee}
En espanol: {helpb ksmmd_es}
{p_end}
