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
on a weight-proportional subsample of up to 2,000 observations{p_end}
{synopt:{opt nf:eatures(#)}}number of random Fourier features (the
approximation's dimension {it:D}); default {cmd:nfeatures(200)},
rounded up to an even number if needed{p_end}
{synopt:{opt mmdtype(string)}}{cmd:vspool} (default),
{cmd:maxpairwise} or {cmd:fuse} -- see {help ksmmd##remarks_mmdtype:Remarks}{p_end}

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
Jitkrittum & Kanagawa 2017) computed on a subsample of up to 2,000
observations (not the full dataset, for cost reasons), drawn with
probability proportional to the survey weight (v0.7 -- see
{help ksmmd##remarks_rff:Remarks}). Pass a positive value to fix it
yourself, e.g. for comparability across repeated calls.

{phang}
{opt nfeatures(#)} is {it:D}, the number of random Fourier features
used to approximate the RBF kernel. Default {cmd:nfeatures(200)},
rounded up to an even number if an odd value is passed (the v0.7
"z-tilde" feature construction always produces an even number of
columns -- see {help ksmmd##remarks_rff:Remarks}).
Larger {it:D} tightens the MMD approximation (expected error shrinks
like {it:D}^-0.5 -- Sutherland & Schneider 2015) at a proportional
compute cost; see {help ksmmd##remarks_agile:Remarks: agile vs final}.

{phang}
{opt mmdtype(string)} selects the k-sample combination rule for MMD:
{cmd:vspool} (default), {cmd:maxpairwise}, or {cmd:fuse}. See
{help ksmmd##remarks_mmdtype:Remarks} for the exact formulas, the
citations, why a third option from an earlier version
({cmd:pairwise}) was removed as mathematically redundant with
{cmd:vspool}, and {cmd:fuse}'s validation status. {opt bw()} is
{bf:ignored} when {cmd:mmdtype(fuse)} is given -- {cmd:fuse} always
anchors its own internal bandwidth grid to the median heuristic.

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
{phang2}{help ksmmd##remarks_combo:Why combine KS and MMD}{p_end}
{phang2}{help ksmmd##remarks_mmdtype:mmdtype() -- vspool, maxpairwise, and fuse}{p_end}
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

{marker remarks_combo}{...}
{pstd}{bf:Why combine KS and MMD}

{pstd}
The two statistics are not paired only for this package's convenience.
Kiefer (1959, Sec. 6, full text read) shows {bf:sup}-type tests (his T,
which is KS's k-sample generalization) carry a guaranteed minimum power
against {it:any} pointwise alternative; {bf:integral}-type tests (such
as omega^2-type tests, and MMD is one of that family) do not have that
guarantee, but can be more powerful against alternatives that are
diffuse rather than concentrated at a single point -- KS and MMD are
complementary by design. Ong, Chen, Zhu & Zhang (2023) make the same
point from the MMD side: they explicitly recommend running an MMD-type
test {bf:and} an energy-distance-type test together, because in
practice it is rarely known in advance whether two distributions differ
in location/shape (KS's strength) or in higher moments/covariance
structure (MMD's strength).

{pstd}
Separately, Kiefer's T does not require the group sizes n_j/N to
converge to fixed proportions as N grows -- reassuring for unbalanced
groups (a common case when {opt by()} groups by year and cohort sizes
differ). The paper's own discussion of non-continuous F (ties) is
consistent with this command's tie-handling (the {cmd:jumpmask}
internal to the Mata code: ties are never treated as evidence, which is
conservative -- it can only make the test slightly less powerful, never
anti-conservative).

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
k-sample framework, Zhang, Guo & Zhou (2024, {it:J. Econometrics}
239(2)) -- the same statistic up to a positive constant ({it:Wtot}, the
total weight, which does not depend on the label permutation and
therefore never changes the permutation p-value).

{pstd}
{bf:v0.7:} {cmd:ksmmd} computes this identity's pairwise-sum form
directly, T_MMD = (1/Wtot) * sum_{{c a<b}} Wsum_a*Wsum_b*||mu_a-mu_b||^2_U,
using the {bf:unbiased} (U-statistic) form of ||.||^2_U rather than the
biased (V-statistic) form used through v0.6 -- Gretton et al. (2012)
give both for the 2-sample case; the choice matters here because the
biased form's "self" term for each group includes same-unit pairs
(i=i'), whose weighted contribution is a fixed additive constant under
{it:equal} weights (so it never affected the permutation p-value) but
is {bf:not} fixed under unequal survey weights (it depends on which
units land in which group under each permutation), a potential source
of subtle power loss. The unbiased form removes those same-unit terms
group by group (falling back to the biased term only if a group's
own de-bias denominator is numerically unsafe, e.g. an extremely small
or weight-concentrated group). {cmd:mmdtype(maxpairwise)} gets the same
treatment, for consistency -- see below. This changes {bf:only} which
estimator is used (not validity: Hemerik & Goeman's permutation theorem
holds for any fixed statistic); re-validated by simulation (Type-I
error, R=2,000, k=4, same 3 adversarial weight scenarios --
{cmd:sim/simulacion_ksmmd_v07_tipo1.py} /
{cmd:resultados_ksmmd_v07_tipo1.txt} -- rejection rates 3.6%-5.8% across
scenarios and all 3 {opt mmdtype()} options, no inflation vs. the 5%
nominal level; a preceding algebraic sanity check confirms the
pairwise-sum rewrite matches the "against the pool" formula above to
floating-point precision when the unbiasing is turned off).

{pstd}
The bridge to Rizzo & Szekely's
DISCO/energy-distance framework, via Sejdinovic, Sriperumbudur, Gretton
& Fukumizu (2013), is real but has a precise scope (full text read):
Rizzo & Szekely (2010, DISCO), Corollary 2, shows the "each group
against the pool" decomposition exists {bf:only} for a {bf:quadratic}
(RKHS-type) distance -- the original energy distance of Szekely & Rizzo
(2004) uses a non-quadratic exponent and has no such decomposition,
only a pairwise sum. That is exactly why {cmd:vspool} needs a kernel
(a quadratic form), not just any distance. Also, the kernel that makes
MMD {bf:equal} to the literal Euclidean energy distance is {bf:not}
RBF -- it is an unbounded kernel, k1(z,z')=0.5*(||z||+||z'||-||z-z'||).
RBF does generate a negative-type semimetric (so it still detects any
distributional difference, not just a mean shift), but it is a
{bf:bounded/saturated} version of the Euclidean one, not the Euclidean
energy distance itself.

{pstd}
{cmd:mmdtype(maxpairwise)}:

{p 8 8 2}T_MMD = max_{{c k<l}} [Wsum_k*Wsum_l/(Wsum_k+Wsum_l)] * ||mu_k - mu_l||^2_U{p_end}

{pstd}
Kim (2021, {it:Bernoulli} 27(1)), weighted form for unequal sizes (his
Remark 3.3, adapted here with {cmd:Wsum} in place of {it:n} for
continuous survey weights). Unlike {cmd:vspool} (which averages the
discrepancy across {it:all} groups), {cmd:maxpairwise} is sensitive to
a {it:single} pair of groups differing sharply even when every other
pair is identical -- a genuinely different alternative-hypothesis
profile, not a rescaling of {cmd:vspool}.

{pstd}
The paper (full text read) gives explicit guidance on when each shape
is preferable: {cmd:maxpairwise} is built for {it:sparse} alternatives
(a single group differs from the rest); {cmd:vspool}/{cmd:fuse} are
built for {it:dense} alternatives (many groups differ). Average-type
statistics lose power as k grows under sparse alternatives;
{cmd:maxpairwise} keeps it. Its minimax optimality (the paper's Sec. 6)
is conditioned on technical kernel assumptions (bounded/sub-Gaussian)
and a specific alternative class, and does {bf:not} automatically carry
over to the survey-weighted version implemented here.

{pstd}
An earlier version of this command offered a third option,
{cmd:mmdtype(pairwise)}, computed {it:without} the
{cmd:Wsum_k*Wsum_l/Wtot} weight. Once that weight is added it becomes
{bf:exactly} {cmd:vspool} (not merely proportional -- the identical
number), so it was removed as redundant rather than kept as a third,
illusory alternative.

{pstd}
{cmd:mmdtype(fuse)} (added in v0.4) -- MMD-FUSE (Biggs, Schrab &
Gretton 2023, NeurIPS): instead of one bandwidth chosen by the median
heuristic, it combines {cmd:vspool}'s (unbiased, v0.7) T_MMD across a
{bf:grid} of bandwidths via a KL-regularized soft-max, avoiding both a
Bonferroni correction and splitting the sample:

{p 8 8 2}T_FUSE = (1/lambda) * log( mean_g[ exp(lambda * T_g) ] ),
T_g = T_MMD_vspool_U(bw_g, kernel_g) / sqrt(Nhat(g)){p_end}

{pstd}
where {cmd:Nhat(g)} rescales each grid point's T_MMD onto a common
scale before combining them (otherwise the point with the
highest-variance features would dominate the log-sum-exp regardless of
whether it carries more real evidence). The permutation-calibration
theorem (Hemerik & Goeman 2018) holds for {bf:any} fixed statistic, so
the grid and {cmd:lambda} do not need literature backing for the
permutation p-value to stay exact under the null; its 2 concrete
conditions are both satisfied here: (a) the observed statistic is
evaluated as one more permutation (the "+1" in (count+1)/(reps+1)), and
(b) the grid and {cmd:lambda} are fixed {bf:before} seeing each run's
permutations (they never depend on the data being tested).

{pstd}
{bf:v0.7:} both the grid and {cmd:lambda} now follow the MMD-FUSE
paper directly (full text read), generalized to {cmd:ksmmd}'s
k-group, weighted, RFF setting:

{phang2}o {bf:lambda} = sqrt(n_min*(n_min-1)), n_min = the size of the
{it:smallest} group -- the paper's own formula (its Theorems 2-3
require lambda asymptotically proportional to n for optimal power,
and every experiment in the paper uses exactly this with n the smaller
sample size in its 2-sample setting; this matches the paper exactly at
k=2, and extends to k>2 via the smallest group as {cmd:ksmmd}'s own
design choice, not the paper's). Replaces the fixed
{cmd:lambda=0.1} used through v0.6, itself the outcome of a systematic
Python/numpy search over simulated data
({cmd:sim/prototipo_mmd_fuse*.py}) run because the paper's formula had
not yet been tested in this command's weighted/RFF context.{p_end}
{phang2}o {bf:grid}: 10 bandwidths -- 5 from a uniform discretization
between 0.5x the 5th percentile and 2x the 95th percentile of
inter-unit distances (on a {it:weighted} subsample, v0.7 -- see below),
times {bf:2} kernel families, Gaussian {bf:and} Laplace, matching the
paper's own empirically validated design (its Appendix A.2/A.4, which
uses 10-20 bandwidths per family across the same 2 families). The
paper's range is wider (10-20 vs. 5 per family here) purely for memory
cost at survey scale (N~10^5) -- see below. Replaces the fixed 4-point
grid (1x, 1.5x, 2x, 3x times the median heuristic, Gaussian only) used
through v0.6.{p_end}

{pstd}
Both changes are re-validated by simulation (Type-I error, R=2,000,
k=4 -- the real production use, grouping {opt by(year)} -- same 3
adversarial weight scenarios as the rest of this command:
{cmd:sim/simulacion_ksmmd_v07_tipo1.py} /
{cmd:resultados_ksmmd_v07_tipo1.txt}; rejection rates 3.6%-5.8% across
scenarios, no inflation vs. the 5% nominal level, for {cmd:fuse}
{bf:and} both other {opt mmdtype()} options in the same run). The
earlier grid's power validation (R=20,000 Type-I check at k=2 and k=4,
plus an exact-kernel Python prototype robust to both a location shift
and a scale/dispersion difference -- {cmd:sim/resultados_ksmmd_mmd_fuse_*_tipo1.txt},
{cmd:sim/prototipo_mmd_fuse*.py}) remains as a record of the v0.4-v0.6
design's own validation; it does not carry over automatically to the
new grid, but nothing in the new grid's construction (a strict
superset in spirit: wider bandwidth coverage, a second kernel family)
suggests it should be less powerful.

{pstd}
The grid and {cmd:lambda} are {bf:still not} configurable through
options -- exposing them would widen the validation surface without
evidence that another combination is better. {opt bw()} is ignored
with {cmd:mmdtype(fuse)} for the same reason. Memory cost: {cmd:fuse}
builds {opt nfeatures()} random features for {bf:each} of its 10 grid
points (10x the {cmd:Phi} memory of {cmd:vspool}/{cmd:maxpairwise} at
the same {opt nfeatures()} -- at the default {opt nfeatures(200)} that
is 2,000 total RFF columns, the same order of magnitude as the
{opt reps(200)} {opt nfeatures(500)} / 4-grid-point configuration
(2,000 columns) already confirmed with no memory problem on real
production data (N=141,151) in v0.4 -- see the validation note below).
{cmd:Nhat(g)} is still computed on a subsample of up to 300
observations rather than the full pooled dataset (for cost) -- the
paper's own Definition 1 uses the full dataset; this remains a
deliberate, documented departure, a possible power loss (not a
validity risk).

{pstd}
{bf:Validation status specific to fuse}: the {bf:v0.4-v0.6} Mata code
for {cmd:fuse} (fixed 4-point grid, lambda=0.1) was confirmed against
real Stata at two scales -- see the record kept in {cmd:ksmmd.ado}'s
header for the exact runs and values. The {bf:v0.7} rewrite (new grid,
new lambda, the Laplace kernel, the unbiased U-statistic, the weighted
median heuristic) was written and validated in Python/numpy (algebraic
sanity check plus the Type-I simulation above) without a real Stata
session available in that development environment, the same situation
already documented for v0.3/v0.4's own first releases. {bf:Confirmed}
at small scale (21sep2026, {cmd:auto.dta}, 5 syntax variants run
against real Stata -- {cmd:vspool} unweighted, {cmd:vspool} weighted
with {opt graph}/{opt posthoc}, {opt mmdtype(maxpairwise)},
{opt ksonly}, {opt mmdtype(fuse)}): all 5 ran with {bf:no error}.
{bf:Also confirmed at production scale} the same day (a real survey
outcome grouped by an ordinal variable, N~141,000): a first batch of 5
configurations
(including {opt graph}/{opt posthoc}, a fixed {opt bw()},
{opt ksonly}/{opt mmdonly}, and an agile pass) used
{opt mmdtype(vspool)} throughout, and a second batch -- run after the
bug fix below -- added {opt mmdtype(maxpairwise)} and
{opt mmdtype(fuse)} (at both {opt nfeatures(200)} and
{opt nfeatures(500)}, i.e. 10x500=5,000 {cmd:Phi} columns, the
memory-untested configuration flagged in an earlier version of this
note) with {opt posthoc}, all with {bf:no error}. {bf:All 3}
{opt mmdtype()} options and KS are now confirmed at {bf:both} scales;
no configuration remains outstanding for v0.7. See {cmd:ksmmd.ado}'s
header for the exact statistics and timings for both scales.

{pstd}
{bf:About negative T_MMD values}: all 3 {opt mmdtype()} options can now
report a {bf:negative} T_MMD (seen in the real-Stata run above, e.g.
T_MMD=-0.1721) -- this is expected, not a bug. Through v0.6, T_MMD was
a biased (V-statistic) quantity, always >= 0. The v0.7 unbiased
(U-statistic) estimator targets a population quantity (MMD^2) whose
floor is exactly 0 under the null; an estimator that is unbiased for a
value at the floor of its own range must be able to go both ways, or it
would be biased upward -- Gretton et al. (2012) document exactly this
for the 2-sample case. Under (or near) the null, the estimator
fluctuates around 0, so small negative values are the expected
signature that the null is close to true, not evidence of an error. The
permutation p-value stays valid regardless: it is calibrated against
the same null distribution, which fluctuates the same way, so a very
negative observed T_MMD naturally yields a {bf:high} p-value (as in the
{cmd:fuse} example above, p=0.9142).

{pstd}
{bf:Bug found and fixed} (21sep2026): {cmd:mmdtype(maxpairwise)}
specifically had a real bug tied to this new negative-value behavior --
found by the user in a production run, where a post-hoc pair (k=2)
whose true statistic was negative was silently reported as
T_MMD=0.0000 and p=1.0000, {bf:exactly}, instead of the real negative
value. Root cause: the running maximum was initialized at 0 (correct
for {cmd:vspool}'s running {it:sum}, wrong for {cmd:maxpairwise}'s
running {it:max} once terms can be negative) -- fixed by initializing
it at a very negative sentinel instead, so the true maximum (positive
or negative) is always found; re-validated by a fresh Type-I simulation
(no inflation) and a dedicated sanity check. See
{cmd:ksmmd.ado}'s header for the full root-cause writeup. This bug did
{bf:not} affect {cmd:vspool} or {cmd:fuse} (which only ever uses the
{cmd:vspool} branch internally) -- it was isolated to
{cmd:mmdtype(maxpairwise)}. Any {cmd:mmdtype(maxpairwise)} run made
with a {cmd:ksmmd.ado} from before this fix should be re-run. The fix
itself was confirmed the same day with a production-scale re-run
(same real survey data): the same two post-hoc pairs that had
previously shown T_MMD=0.0000/p=1.0000 now correctly showed their real
negative values (T_MMD=-174.9475 and -361.6898), matching
{cmd:vspool}'s own post-hoc for those pairs almost exactly -- expected,
since {cmd:vspool} and {cmd:maxpairwise} are algebraically the same
statistic at k=2 (see the discussion above).

{marker remarks_rff}{...}
{pstd}{bf:MMD via Random Fourier Features}

{pstd}
An exact RBF-kernel MMD needs the full N x N kernel matrix -- O(N^2),
infeasible once N is in the hundreds of thousands (the exact problem
that made {cmd:mmd_2s} too slow in production for this scenario).
{cmd:ksmmd} instead approximates the kernel with {opt nfeatures()}
random Fourier features (Rahimi & Recht 2007), turning the cost into
O(reps * N * D), linear in {it:N}. Since v0.7, the features are the
lower-variance "z-tilde" construction (Sutherland & Schneider 2015,
eqs. 5-7): phi(x) = sqrt(1/(D/2)) * [cos(omega_1 x), sin(omega_1 x),
..., cos(omega_{{c D/2}} x), sin(omega_{{c D/2}} x)], omega_m ~ N(0,
1/bw^2) -- {it:no} random phase and D/2 frequencies, instead of the
earlier ("z-breve") D-frequency cosine-with-random-phase construction.
Same computational cost, strictly lower variance for the Gaussian
kernel at the same {it:D}. {opt nfeatures()} is silently rounded up to
an even number if needed, since this construction always returns an
even number of columns (D/2 cosines + D/2 sines).

{pstd}
The known error bound is on the MMD statistic itself (not its square),
not just the kernel (Sutherland & Schneider 2015, Section 3.3):
P(|MMD_RFF - MMD| >= eps) <= 2*exp(-D*eps^2/128), expected absolute
error <= 8*sqrt(2*pi/D) -- halving the expected error requires
{bf:quadrupling} {opt nfeatures()}. ({bf:Corrected} sep2026, after
reading the full paper text with cross-checked extraction: an earlier
"correction" dated 19sep2026, made from search-based bibliography
verification without full-text access, had wrongly changed this bound
to MMD^2 and cited it as "Theorem 1" -- the paper's primary text
(p. 7) confirms the bound is on MMD un-squared, and the result is an
unnumbered paragraph in Section 3.3, not a numbered theorem (the paper
has no numbered theorems, only Propositions 1-10). Both errors are
reverted here.) Choi, I. & Kim, I. (2024) go further than "can lose
power": their Theorem 3 proves genuine {it:inconsistency} with fixed
{it:D} -- infinitely many pairs of distinct distributions exist where
asymptotic power stays bounded by alpha regardless of sample size, if
D does not grow with N. There is no universal rate D=O(sqrt(N)); the
needed rate depends on the smoothness of the (unobservable)
alternative (their Theorems 6-7, Prop. 8). Empirically, in their
univariate case (d=1, the same case {cmd:ksmmd} targets) D=200 already
matches exact-MMD power -- supporting the {opt nfeatures(200)} default
-- but their Theorem 7 also warns that raising D up to the smallest
group size recovers the optimal rate only at essentially O(N^2) cost
again, so {opt nfeatures()} follows the same agile-then-final logic as
{opt reps()} (low to explore, higher -- not arbitrarily high -- for
the reported result; see {help ksmmd##remarks_agile:Remarks} below).

{pstd}
Separately from the RFF approximation, MMD's power against a location
shift is itself bandwidth-dependent for a more basic reason (Reddi,
Ramdas, Poczos, Singh & Wasserman 2015, Lemma 1): population MMD^2
with a Gaussian kernel scales as 2*shift^2/bandwidth^2 (1+o(1)) -- a
bandwidth large relative to the shift dilutes the signal
{bf:quadratically}, not exponentially ({bf:corrected} sep2026: an
earlier version of this note said "exponentially small," which the
paper does not support; its formal power theorem is also explicitly a
high-dimensional result, n and d jointly to infinity with
bandwidth=Omega(sqrt(d)), so it does not literally apply to a scalar
variable like age, d=1 -- only the Lemma 1 mechanism generalizes to
d=1 by algebraic analogy). Either way, a poorly chosen {opt bw()} can
miss a real difference that KS still detects (this is part of the
motivation for {cmd:mmdtype(fuse)}, see
{help ksmmd##remarks_mmdtype:Remarks}).

{pstd}
{opt bw(-1)} (the default) uses the median-heuristic bandwidth
(Garreau, Jitkrittum & Kanagawa 2017) on a subsample of up to 2,000
observations, not the full dataset -- computing the exact median of
all pairwise distances is itself O(n^2). {bf:v0.7:} that subsample is
drawn with probability proportional to the survey weight (an
Efraimidis-Spirakis weighted sample without replacement) rather than
uniformly, as it was through v0.6 -- a design inconsistency fixed, no
paper in this bibliography covers the median heuristic under weights,
so this is {cmd:ksmmd}'s own extension, re-validated by the Type-I
simulation cited in {help ksmmd##remarks_mmdtype:Remarks} (mmdtype()).
Convention note (full text
read): {cmd:ksmmd} uses bw = median(|y_i-y_j|) = sqrt(Hn), where Hn is
the median of {it:squared} pairwise distances; the paper's main formula
is nu=sqrt(Hn/2), a factor sqrt(2) smaller, but its own footnote 1
acknowledges "some authors simply choose nu=sqrt(Hn)" -- {cmd:ksmmd}'s
convention is a real variant in the literature, not an error. The
paper's Sec. 4 also shows {bf:empirically} that the median heuristic
picks too large a bandwidth specifically when groups differ in
{bf:variance/scale} rather than location -- independent support (beyond
this package's own simulations) for using {cmd:mmdtype(fuse)} when a
dispersion difference, not just a shift, is suspected.

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
package's {cmd:sim/} directory), not a citation. That simulation was
first run (through v0.6) for {cmd:vspool}
({cmd:sim/simulacion_ksmmd_mmd_tipo1.py} /
{cmd:resultados_ksmmd_mmd_tipo1.txt}) and {cmd:maxpairwise}
({cmd:sim/simulacion_ksmmd_mmd_maxpairwise_tipo1.py} /
{cmd:resultados_ksmmd_mmd_maxpairwise_tipo1.txt}) -- same 3-scenario
design as the {cmd:kstest} simulation in both cases, worst-case
rejection rate under a true null around 6% (vs. 5% nominal) for
either option, consistent with, and no worse than, {cmd:kstest}'s own
result. {bf:v0.7} redid this validation from scratch for the redesigned
estimator (unbiased U-statistic, z-tilde RFF, weighted median
heuristic -- see {help ksmmd##remarks_mmdtype:Remarks} for {cmd:fuse}'s
own grid/lambda changes), all 3 {opt mmdtype()} options together, R=2,000
at k=4:
{cmd:sim/simulacion_ksmmd_v07_tipo1.py} /
{cmd:resultados_ksmmd_v07_tipo1.txt} -- rejection rates 3.6%-5.8% across
the same 3 scenarios, no worse than the earlier design.

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

{pstd}
{bf:Example 5: fuse}, combining a grid of bandwidths instead of one
(see {help ksmmd##remarks_mmdtype:Remarks} for its validation status
before using it in production):{p_end}
{phang2}{cmd:* Example 5: fuse}{p_end}
{phang2}{cmd:. ksmmd mpg [aweight=wgt], by(g) mmdtype(fuse) reps(500)}{p_end}


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
{synopt:{cmd:r(mmdtype)}}{cmd:vspool}, {cmd:maxpairwise}, or {cmd:fuse}{p_end}

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
Cramer-v. Mises tests. {it:Ann. Math. Statist.} 30(2), 420-447. DOI:
10.1214/aoms/1177706261.

{pstd}
Gretton, A., Borgwardt, K.M., Rasch, M.J., Scholkopf, B., Smola, A.
(2012). A Kernel Two-Sample Test. {it:JMLR} 13(25), 723-773.

{pstd}
Rahimi, A., Recht, B. (2007). Random Features for Large-Scale Kernel
Machines. {it:NeurIPS} 20.

{pstd}
Biggs, F., Schrab, A., Gretton, A. (2023). MMD-FUSE: Learning and
Combining Kernels for Two-Sample Testing Without Data Splitting.
{it:NeurIPS} 36. arXiv:2306.08777.

{pstd}
Hemerik, J., Goeman, J.J. (2018). Exact testing with random
permutations. {it:Test} 27(4), 811-825. DOI: 10.1007/s11749-017-0571-1.

{pstd}
Sutherland, D.J., Schneider, J. (2015). On the Error of Random Fourier
Features. {it:UAI} 2015.

{pstd}
Ong, Z.P., Chen, A.A., Zhu, T., Zhang, J.-T. (2023). Testing Equality
of Several Distributions at High Dimensions: A Maximum-Mean-
Discrepancy-Based Approach. {it:Mathematics} 11(20), 4374. DOI:
10.3390/math11204374. ({bf:Corrected} 19sep2026 -- an earlier version
of this citation had the wrong authors and the wrong article number;
see the verification note in {cmd:ksmmd.ado}'s header.)

{pstd}
Zhang, J.-T., Guo, J., Zhou, B. (2024). Testing equality of several
distributions in separable metric spaces: a maximum mean discrepancy
based approach. {it:J. Econometrics} 239(2). ({bf:Corrected}
19sep2026 -- same reason as above: wrong authors, wrong year.)

{pstd}
Kim, I. (2021). Comparing a large number of multivariate
distributions. {it:Bernoulli} 27(1), 419-441. DOI: 10.3150/20-BEJ1244.

{pstd}
Sejdinovic, D., Sriperumbudur, B., Gretton, A., Fukumizu, K. (2013).
Equivalence of distance-based and RKHS-based statistics in hypothesis
testing. {it:Ann. Statist.} 41(5), 2263-2291. DOI: 10.1214/13-AOS1140.

{pstd}
Rizzo, M.L., Szekely, G.J. (2010). DISCO analysis: a nonparametric
extension of analysis of variance. {it:Ann. Appl. Stat.} 4(2),
1034-1055. DOI: 10.1214/09-AOAS245.

{pstd}
Szekely, G.J., Rizzo, M.L. (2004). Testing for Equal Distributions in
High Dimension. {it:InterStat}, Nov(5).

{pstd}
Rizzo, M.L., Szekely, G.J. (2016). Energy distance. {it:WIREs
Computational Statistics} 8(1), 27-38. DOI: 10.1002/wics.1375.

{pstd}
Garreau, D., Jitkrittum, W., Kanagawa, M. (2017). Large sample
analysis of the median heuristic. arXiv:1707.07269.

{pstd}
Reddi, S.J., Ramdas, A., Poczos, B., Singh, A., Wasserman, L. (2015).
On the High Dimensional Power of a Linear-Time Two Sample Test under
Mean-shift Alternatives. {it:Proc. AISTATS 2015}, PMLR v38.
arXiv:1411.6314.

{pstd}
Choi, I., Kim, I. (2024). Computational-Statistical Trade-off in
Kernel Two-Sample Testing with Random Fourier Features. arXiv:2407.08976.
({bf:Corrected} sep2026, after reading the full paper: first author is
Ikjun Choi, correct initial "I.", not "S." -- a third real attribution
error in this bibliography, this time caught by full-text reading
rather than metadata search.)

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
Version 0.4 adds {cmd:mmdtype(fuse)} (MMD-FUSE). Its Type-I-error
control was validated at R=20,000 via a separate Python/numpy
reimplementation of the same algebra (k=2 and k=4, see
{help ksmmd##remarks_mmdtype:Remarks}). The Mata code itself has since
been confirmed against real Stata at both small scale ({cmd:auto.dta})
and production scale (N=141,151, 4 groups, {opt reps(200)}
{opt nfeatures(500)}, 364.97 seconds, no error) -- see
{help ksmmd##remarks_mmdtype:Remarks} for both results.

{pstd}
Version 0.5 also corrects two citation errors in the References
section below (wrong authors, and a wrong article number in one case)
caught when the bibliography was checked against primary-source
metadata on 19sep2026, in response to a direct question about whether
these citations had been verified against the original document
before their formulas were used -- they had not; see the verification
note near the end of {cmd:ksmmd.ado}'s header for what was and was not
checked.

{pstd}
Version 0.6 revises the bibliography against the {bf:full} PDFs
(shared by the user via Google Drive; 15 of 16 read cover to cover).
That full-text reading found 3 further corrections the version-0.5
metadata check could not catch (content/formula errors, not just
author/year/DOI): the Sutherland & Schneider bound (reverted from
MMD^2 to MMD, citation corrected from "Theorem 1" to "Section 3.3"),
the {cmd:mmdtype(fuse)} motivation (Reddi et al.'s mechanism is
quadratic scaling, not exponential), and a third attribution error
(Choi, I., not Choi, S.) -- plus a clarification that the MMD-FUSE
paper does recommend a lambda value (lambda~n), which {cmd:ksmmd}
deliberately departs from. No algebra or Mata changed -- no T_KS/
T_MMD/p-value differs from this version, only documentation text; see
{cmd:ksmmd.ado}'s header (v0.6) for the full detail of the corrections
and the documentation improvements added.

{pstd}
Version 0.7 implements the 5 design improvements that v0.6's reading
had flagged as future work, each re-validated by its own Type-I-error
Monte Carlo simulation before being applied (R=2,000, k=4, same 3
adversarial weight scenarios as the rest of this command --
{cmd:sim/simulacion_ksmmd_v07_tipo1.py} /
{cmd:resultados_ksmmd_v07_tipo1.txt} -- rejection rates 3.6%-5.8%
across scenarios for {opt mmdtype(vspool)}, {opt mmdtype(maxpairwise)}
{bf:and} {opt mmdtype(fuse)}, no inflation vs. the 5% nominal level; an
algebraic sanity check separately confirms the rewritten estimator
reduces to the v0.6 formula, to floating-point precision, when the new
unbiasing is turned off): an unbiased (U-statistic) MMD estimator, a
lower-variance "z-tilde" random-Fourier-feature construction, a
lambda~n formula and a quantile-based, 2-kernel-family bandwidth grid
for {opt mmdtype(fuse)}, and a weighted (rather than uniform) subsample
for the median-heuristic bandwidth. T_KS is unchanged; T_MMD values
{bf:do} change from v0.6 under all 3 {opt mmdtype()} options (a
different, more efficient estimator of the same population quantity,
not a different null hypothesis) -- see
{help ksmmd##remarks_mmdtype:Remarks} (mmdtype()) and
{help ksmmd##remarks_rff:Remarks} (MMD via Random Fourier Features)
for the detail of each change. This version's Mata rewrite has been
{bf:confirmed against real Stata at both scales} (21sep2026): small
scale ({cmd:auto.dta}, 5 syntax variants covering all 3
{opt mmdtype()} options, all ran with no error) and {bf:production
scale} (a real survey outcome grouped by an ordinal variable, N~141,000
across 4 groups, weighted by a continuous survey weight,
{opt reps(200)} {opt nfeatures(500)} with {opt graph}/{opt posthoc}:
155.42 seconds, no error; plus
{opt ksonly}, {opt mmdonly}, a fixed {opt bw()}, and an agile
{opt reps(50)} {opt nfeatures(50)} pass; plus, after a real bug found
and fixed in {opt mmdtype(maxpairwise)} that same day (see the
validation note below), a follow-up production run confirming
{opt mmdtype(maxpairwise)} and {opt mmdtype(fuse)} too, including
{opt fuse} at {opt nfeatures(500)} -- 5,000 {cmd:Phi} columns, no
memory problem). KS and {bf:all 3} {opt mmdtype()} options are now
confirmed at {bf:both} scales; no configuration remains outstanding
for v0.7. See the validation note under
{help ksmmd##remarks_mmdtype:Remarks} (mmdtype()) for the exact runs
and values, the bug/fix writeup, and why T_MMD can now be negative
(expected, not a bug).

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
