{smcl}
{* *! version 1.5.0  26aug2026}{...}
{vieweralsosee "[R] svy: mean" "help mean"}{...}
{vieweralsosee "[R] svy: total" "help total"}{...}
{vieweralsosee "[R] svy: proportion" "help proportion"}{...}
{vieweralsosee "[R] svy postestimation" "help svy postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tsvy" "help tsvy"}{...}
{vieweralsosee "svylet (en espanol)" "help svylet_es"}{...}
{viewerjumpto "Syntax" "svylet##syntax"}{...}
{viewerjumpto "Description" "svylet##description"}{...}
{viewerjumpto "Options" "svylet##options"}{...}
{viewerjumpto "Remarks" "svylet##remarks"}{...}
{viewerjumpto "Examples" "svylet##examples"}{...}
{viewerjumpto "Stored results" "svylet##results"}{...}
{viewerjumpto "References" "svylet##references"}{...}
{viewerjumpto "Author" "svylet##author"}{...}
{viewerjumpto "Also see" "svylet##also_see"}{...}
{hline}
{title:Title}

{phang}
{bf:svylet} {hline 2} Wald omnibus F-test, Bonferroni pairwise comparisons,
and Compact Letter Display, for {cmd:svy:}{space 1}{cmd:mean}/{cmd:total}/
{cmd:proportion}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:svylet}
{it:varname}
{ifin}{cmd:,}
{cmdab:over:(}{it:varname}{cmd:)}
{cmdab:stat:(}{it:statname}{cmd:)}
[{it:options}]

{pstd}
where {it:statname} is one of {cmd:mean}, {cmd:total}, {cmd:proportion}, or
{cmd:ratio}.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt over(varname)}}variable that defines the groups to compare;
required{p_end}
{synopt:{opt stat(statname)}}statistic to estimate and compare:
{cmd:mean}, {cmd:total}, {cmd:proportion}, or {cmd:ratio}; required{p_end}
{synopt:{opt l:evel(#)}}category of {it:varname} to test, when
{cmd:stat(proportion)}; default is {cmd:level(1)}. Ignored (with a note)
for {cmd:mean}, {cmd:total}, and {cmd:ratio}{p_end}
{synopt:{opt d:enominator(varname)}}denominator variable, when
{cmd:stat(ratio)} -- {it:varname} (the main argument) is the numerator.
Required with {cmd:stat(ratio)}, ignored (with a note) otherwise{p_end}
{synopt:{opt a:lpha(#)}}significance level used for the Bonferroni pairwise
comparisons and the Compact Letter Display; default is {cmd:alpha(0.05)}{p_end}

{syntab:Vs-a-reference (optional)}
{synopt:{opt ref(#)}}value of {cmd:over()} to use as a fixed baseline
category. Adds {cmd:k-1} Bonferroni-corrected Wald contrasts (each other
category against {cmd:ref()}) alongside the all-pairs CLD -- a DIFFERENT
family of hypotheses, not a replacement; see
{help svylet##remarks_ref:Remarks}{p_end}

{syntab:Bootstrap (optional)}
{synopt:{opt boot(#)}}number of bootstrap replications for a prepivoted
p-value of the omnibus F-test; default is {cmd:boot(0)}, meaning the
analytic p-value only{p_end}
{synopt:{opt bseed(#)}}random-number seed set with {cmd:set seed} before
the {cmd:boot()} replications; default lets Stata's current seed stand{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:varname} must be numeric. {cmd:fweight}s, {cmd:pweight}s, and design
variables are not specified on {cmd:svylet} itself: the dataset must
already be {helpb svyset} before calling {cmd:svylet}, exactly as for
{cmd:svy:}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:svylet} targets any complex-survey setting with a multistage,
stratified-cluster design and survey weights -- household budget and
labor-force surveys, demographic and health surveys, panel household
surveys, and similar public-use microdata -- where a researcher already
uses {cmd:svy:} and needs a design-based significance test across the
categories of a grouping variable (years, waves, regions, cohorts),
not just the point estimates that {cmd:svy:} itself reports.

{pstd}
{cmd:svylet} answers the question that {cmd:svy:}{space 1}{cmd:mean},
{cmd:total}, and {cmd:proportion} with {cmd:over()} leave open: are the
{it:k} group estimates actually different from one another, accounting for
the survey design? It runs the corresponding {cmd:svy:} command once
internally, then:

{phang2}1. tests the omnibus null hypothesis that all {it:k} group
estimates are equal, using a Wald F-test with the Korn & Graubard (1990)
degrees-of-freedom adjustment (the same adjustment {cmd:test}/{cmd:testparm}
apply by default after {cmd:svy:});{p_end}
{phang2}2. tests every pairwise comparison among the {it:k} groups, with a
Bonferroni correction for the k(k-1)/2 comparisons;{p_end}
{phang2}3. assigns a Compact Letter Display (CLD): groups that share at
least one letter are not significantly different from each other at
{cmd:alpha()}, after the Bonferroni correction.{p_end}

{pstd}
Because {cmd:svylet} already ran {cmd:svy:} internally, it also exposes the
point estimates, standard errors, confidence limits, and sample sizes by
group through {cmd:return}, so a caller does not need to run the same
{cmd:svy:} command a second time just to build a point-estimate table next
to the test. See {help svylet##results:Stored results} below, and see
{helpb tsvy} for a command that uses exactly this to build a full
table (national/region/department, by year) in one pass.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt over(varname)} specifies the variable whose categories define the
groups to compare (for example, a year variable). It must have at least 2
distinct values in the estimation sample; {cmd:svylet} stops with an error
otherwise. {it:varname} must be NUMERIC -- {cmd:svy: mean}/{cmd:total}/
{cmd:proportion}/{cmd:ratio} do not accept a string {cmd:over()} at all
({cmd:svylet} checks for this and stops with a clear message naming
{helpb encode} as the fix, rather than letting the underlying {cmd:svy:}
call fail with its own less specific error). If {it:varname} has a value
label, {cmd:svylet} does not use it for the test itself (values are only
shown as returned by {cmd:levelsof}), so the mapping from a raw code to a
human-readable label, if you need one, is the caller's responsibility (see
the {cmd:years()} logic in {helpb tsvy} for one way to do this without
depending on a value label).

{phang}
{opt stat(statname)} chooses which {cmd:svy:} command {cmd:svylet} runs
internally: {cmd:mean}, {cmd:total}, {cmd:proportion}, or {cmd:ratio}
(added in version 1.2). Unlike {cmd:svy:} itself, {cmd:svylet} accepts
exactly one analysis variable per call (not a {it:varlist}, and not a
{cmd:num/den} expression for {cmd:ratio} -- see {opt denominator()}
below), because the test is defined over the categories of {cmd:over()}
for a single measured quantity. To test several variables, call
{cmd:svylet} once per variable.

{phang}
{opt level(#)} selects, for {cmd:stat(proportion)} only, which category of
{it:varname} the test and point estimates refer to (the "success" value).
{it:varname} produces one row of output in {cmd:svy: proportion} for every
distinct value it takes; {opt level(#)} tells {cmd:svylet} which of those
rows to carry through the test. It has no effect for {cmd:mean},
{cmd:total}, or {cmd:ratio}, and {cmd:svylet} prints a note if it is set
to something other than its default alongside any of those.

{phang}
{opt denominator(varname)} names the denominator variable, required when
{cmd:stat(ratio)} -- the command's main argument, {it:varname}, is the
numerator. {cmd:svylet} builds the {cmd:num/den} expression that
{cmd:svy: ratio} expects internally; you never write the slash yourself.
{cmd:e(b)}/{cmd:e(V)} from {cmd:svy: ratio ..., over()} have the same
shape as {cmd:mean}/{cmd:total} (one equation, one column per
{cmd:over()} category), so the test, the Bonferroni comparisons, and the
Compact Letter Display work exactly the same way for {cmd:ratio} as for
{cmd:mean}/{cmd:total}. Ignored (with a note) for any other {cmd:stat()}.

{phang}
{opt alpha(#)} sets the significance level for the Bonferroni-adjusted
pairwise comparisons feeding the Compact Letter Display. It does not
affect the omnibus F-test's own p-value, only which groups end up sharing
a letter.

{dlgtab:Bootstrap}

{phang}
{opt boot(#)} requests a bootstrap-calibrated p-value for the omnibus
F-test, in addition to the analytic one, using the prepivoting approach of
Beran (1988) as adapted for hypothesis testing by Hall & Wilson (1991):
pool the data from all {cmd:over()} groups, resample whole primary
sampling units (PSUs) with replacement within their original strata
({helpb bsample}, {cmd:cluster()} {cmd:strata()}), then randomly reassign
each {it:resampled cluster as a whole} to a pseudo-group, in the same
proportions (by cluster count) as the real {cmd:over()} groups, so that
the null hypothesis holds by construction in every replication. See
{help svylet##remarks:Remarks} for why the reassignment happens by whole
cluster and not by individual observation, and {help svylet##references:References}
for the supporting literature. {cmd:boot(0)}, the default, skips this
entirely and reports only the analytic p-value.

{pmore}
{cmd:boot()} requires that the current {helpb svyset} declare both a PSU
and a stratum (any of the internal names Stata's {cmd:svy:} may store
them under -- {cmd:e(psu)}, {cmd:e(psu1)}, {cmd:e(su)}, {cmd:e(su1)}, and
correspondingly for strata -- are tried); {cmd:svylet} stops with a clear
error, showing what each of those macros actually contained, if none of
them resolve to real variables.

{phang}
{opt bseed(#)} passes a seed to {cmd:set seed} immediately before running
the {cmd:boot()} replications, so results are reproducible. If omitted,
whatever seed Stata's random-number generator is already on is used
as-is.


{marker remarks}{...}
{title:Remarks and examples}

{pstd}
Remarks are presented under the following headings:

{phang2}{help svylet##remarks_test:The omnibus F-test and the Korn-Graubard adjustment}{p_end}
{phang2}{help svylet##remarks_cld:Bonferroni pairs and the Compact Letter Display}{p_end}
{phang2}{help svylet##remarks_ref:ref(): comparing against a fixed baseline, not all pairs}{p_end}
{phang2}{help svylet##remarks_degenerate:Degenerate variance (proportions of exactly 0 or 1)}{p_end}
{phang2}{help svylet##remarks_boot:Why boot() resamples and reassigns by whole PSU}{p_end}
{phang2}{help svylet##remarks_limits:What svylet deliberately does not do}{p_end}

{marker remarks_test}{...}
{pstd}{bf:The omnibus F-test and the Korn-Graubard adjustment}

{pstd}
The omnibus test is a Wald test of H0: all {it:k} group means/totals/
proportions are equal, built from the {it:k}-1 contrasts of every group
against the first one. This is mathematically {it:identical} regardless of
which group is used as the reference contrast -- any set of {it:k}-1
independent contrasts spanning the same space gives the same Wald
statistic, because it is a linear reparameterization of the same test.
(An earlier version of {cmd:svylet} accepted a {cmd:refgroup()} option
that appeared to let the caller change the reference group; it was removed
in version 1.1 once this invariance was confirmed algebraically -- there
was nothing for it to do. See the changelog at the top of {cmd:svylet.ado}.)

{pstd}
Stata's own {cmd:test}/{cmd:testparm} after a {cmd:svy:} command apply, by
default, the Korn & Graubard (1990) degrees-of-freedom adjustment: with
{it:k}-1 the dimension of the test and {it:d} = {cmd:e(df_r)} the design
degrees of freedom,

{pmore}
{cmd:F = [(d - (k-1) + 1) / ((k-1)*d)] * W}{space 4}with{space 4}
{cmd:F ~ F(k-1, d-(k-1)+1)}

{pstd}
where {it:W} is the raw Wald statistic. {cmd:svylet} applies the same
adjustment (confirmed by comparing {cmd:svylet}'s output against
{cmd:svy: regress} + {cmd:testparm} on the same design and data).

{marker remarks_cld}{...}
{pstd}{bf:Bonferroni pairs and the Compact Letter Display}

{pstd}
Every one of the {it:k}(k-1)/2 pairs of {cmd:over()} categories is
compared with a design-based t-test, and the raw p-value is multiplied by
the number of pairs (capped at 1) -- the standard Bonferroni correction.
Groups are then assigned to the smallest number of letters such that two
groups share a letter if and only if they belong to some maximal subset of
groups that are all pairwise non-significant at {cmd:alpha()}. This is the
same logic used by {cmd:pwcompare, cld} and by the classic
letter-display output of ANOVA packages: shared letters mean "not
distinguishable here", not "equal".

{marker remarks_ref}{...}
{pstd}{bf:ref(): comparing against a fixed baseline, not all pairs}

{pstd}
GRUPO/CLD and {cmd:ref()} answer two DIFFERENT questions, and can
legitimately disagree on the same data -- neither is "wrong" when they do.
This matters in practice: comparing tsvy's CLD letters against a reference
script that only tested each year against the most recent one found
about 17% of the derived year-vs-2026 calls disagreeing, entirely because
the two procedures test different families of hypotheses (see the tsvy.ado
v1.5 changelog for the worked example).

{pstd}
GRUPO/CLD (the default, always computed) answers "which of these {it:k}
categories differ from EACH OTHER" -- all {it:k}(k-1)/2 pairs are
compared, and the Bonferroni correction multiplies each raw p-value by
{it:k}(k-1)/2. {cmd:ref(#)} answers a narrower, DIFFERENT question --
"which categories differ from THIS ONE baseline category" -- only {it:k}-1
comparisons are in that family, so the Bonferroni correction multiplies by
{it:k}-1 instead. A comparison that survives Bonferroni at {it:k}-1
comparisons can fail to survive it at {it:k}(k-1)/2 comparisons (and,
less intuitively but just as legitimately, the reverse can happen too, in
either direction), because the two corrections are controlling the
family-wise error rate over two DIFFERENT families of hypotheses, not the
same family with a different sample size. Dunn (1961) is the classical
reference for applying the Bonferroni inequality to multiple-comparison
problems, including comparing several groups against one control.

{pstd}
The {it:k}-1 comparisons {cmd:ref()} builds share the same baseline
category, so their test statistics are correlated with each other in a
known way -- an all-pairs procedure (this command's own CLD, Tukey's
method, or a plain Bonferroni split across {it:k}-1 comparisons as
{cmd:ref()} does) does not exploit that correlation and is therefore more
conservative than necessary for this specific family. Dunnett (1955, 1964)
derived a single-step procedure for exactly this "several treatments vs a
control" design that uses the correlation among the {it:k}-1 contrasts to
get sharper (less conservative, more powerful) critical values while still
controlling the family-wise error rate at the nominal level; see also Hsu
(1996, chapter 4) and Bretz, Hothorn & Westfall (2010, chapter 4) for
modern treatments and worked examples (the latter's R package
{cmd:multcomp} implements it as {cmd:contrMat(..., type="Dunnett")}).
{cmd:ref()} in this command uses the simpler Bonferroni split (Dunn 1961),
not the Dunnett single-step critical value -- it is always valid (Bonferroni
never inflates the false-positive rate, regardless of the correlation
structure) but somewhat conservative relative to Dunnett's for this
specific comparison family; implementing genuine Dunnett critical values
requires the multivariate t distribution, not attempted here. See
{help svylet##references:References} below.

{marker remarks_degenerate}{...}
{pstd}{bf:Degenerate variance (proportions of exactly 0 or 1)}

{pstd}
A group with a proportion of exactly 0 or 1 -- common in small domains --
has an undefined or zero design-based variance. Rather than silently
treating that as "no difference" (a missing variance compared against a
number is treated as larger than any real number internally, which would
otherwise merge that group into whatever comparison happens to run last),
{cmd:svylet} flags those categories explicitly, marks their letter as
{cmd:?}, and excludes them from every candidate subset in the Compact
Letter Display. A warning naming the affected categories (by their
position within {cmd:over()}, not their raw value) is printed. Treat
{cmd:?} as "the test could not be computed here", never as "no
difference".

{marker remarks_boot}{...}
{pstd}{bf:Why boot() resamples and reassigns by whole PSU}

{pstd}
{cmd:boot()}'s reassignment step must move whole primary sampling units
(clusters), never individual observations, from their original
{cmd:over()} group to a pseudo-group. Splitting a cluster's observations
across different pseudo-groups destroys the intra-cluster correlation that
the design-based variance estimator (and the observed F-statistic) assumes
when computing variance, understating the variability of the bootstrap
null-reference distribution and inflating the false-positive rate. A Monte
Carlo simulation under a true null hypothesis (10,000 simulated datasets,
199 bootstrap replications each) found the row-level reassignment used by
{cmd:svylet} 1.0 rejected a true null about 9.3% of the time at a nominal
5% level -- nearly double -- while the cluster-level reassignment used
from 1.1 onward rejected about 3.2% of the time (conservative, not
inflated). See {cmd:AUDIT.md} and {cmd:sim/simulacion_bootstrap.py} in the
{cmd:svylet} repository for the full simulation and its results, and
{help svylet##references:References} below for the supporting literature
on why resampling and reassignment under a complex design must preserve
the cluster as the unit of exchangeability.

{marker remarks_limits}{...}
{pstd}{bf:What svylet deliberately does not do}

{phang2}o {cmd:svylet} takes one analysis variable at a time, not a
{it:varlist} -- see {helpb tsvy} for looping this over many variables
and many levels of aggregation at once.{p_end}
{phang2}o {cmd:svylet} does not cross {cmd:over()} with a second grouping
dimension in the same call (for example, "by year, separately within each
region"); subset the data with {cmd:if} and call {cmd:svylet} again for
each region, or use {helpb tsvy}, which does exactly that
internally.{p_end}
{phang2}o the omnibus F-test result does not depend on, and cannot be
changed by, which {cmd:over()} category is treated as the reference (see
{help svylet##remarks_test:above}).{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
The leading {cmd:.} before each line below is the command prompt, shown
here only because that is the standard convention for Stata help files
-- it is not part of the command. Copying a single-line example with the
{cmd:.} included works fine (Stata's do-file runner tolerates it), but
copying a multi-line {cmd:foreach}/{cmd:forvalues} block with a {cmd:.}
left on every line, including the body and the closing brace, breaks
Stata's parsing of the block. When copying a loop example into a do-file,
strip the leading {cmd:.} first.

{pstd}Setup: a design with each observation as its own PSU (no real
clustering in {cmd:auto.dta}, this is only enough for the analytic path){p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen long psu_id = _n}{p_end}
{phang2}{cmd:. svyset psu_id}{p_end}

{pstd}{cmd:proportion}: is the share of imported cars different across
repair-record categories?{p_end}
{phang2}{cmd:. svylet foreign, over(rep78) stat(proportion) level(1)}{p_end}

{pstd}{cmd:mean}: does average mpg differ across repair-record categories?{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean)}{p_end}

{pstd}{cmd:total}: does total vehicle weight differ across repair-record
categories?{p_end}
{phang2}{cmd:. svylet weight, over(rep78) stat(total)}{p_end}

{pstd}{cmd:ratio}: does the trunk-to-length ratio differ across
repair-record categories? {opt denominator()} is a separate option, not a
{cmd:num/den} expression typed into the main argument{p_end}
{phang2}{cmd:. svylet trunk, over(rep78) stat(ratio) denominator(length)}{p_end}

{pstd}{cmd:over()} must be numeric -- if the grouping variable you have is
a STRING (say, {cmd:origin}, holding "Domestic"/"Foreign" text), run it
through {helpb encode} first, then pass the resulting numeric variable:{p_end}
{phang2}{cmd:. decode foreign, generate(origin)}{p_end}
{phang2}{cmd:. encode origin, generate(origin_num)}{p_end}
{phang2}{cmd:. svylet mpg, over(origin_num) stat(mean)}{p_end}

{pstd}With a bootstrap-calibrated p-value (needs a design with real PSUs
and strata; {cmd:industry}/{cmd:south} in {cmd:nlsw88.dta} are used here
only to have multi-row clusters to demonstrate the mechanism, not as a
real survey design):{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. svyset industry, strata(south) singleunit(certainty)}{p_end}
{phang2}{cmd:. svylet wage, over(race) stat(mean) boot(200) bseed(20260824)}{p_end}

{pstd}A looser significance level widens which groups end up sharing a
letter (fewer groups end up "significantly different"), without changing
the omnibus F-test itself, only the pairwise comparisons behind
{cmd:GRUPO}:{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean) alpha(0.10)}{p_end}

{pstd}{cmd:ref()}: compare every {cmd:rep78} category against ONE fixed
baseline (here, 5 = "Excellent") instead of all pairs -- {it:k}-1
Bonferroni-adjusted contrasts (Dunn 1961), a DIFFERENT family of
hypotheses from the all-pairs CLD above (see
{help svylet##remarks_ref:Remarks}). This is the pattern for "did each
group change relative to a reference category/year", the question
{helpb tsvy}'s {cmd:refyear()} answers over time -- see its help for a
worked example with years:{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean) ref(5)}{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. matrix list r(p_vsref)}{p_end}

{pstd}Reading the per-category vs-baseline p-value programmatically
(missing at {cmd:r(ref_idx)}'s own position, and throughout if
{cmd:ref()} was not specified):{p_end}
{phang2}{cmd:. forvalues i = 1/`r(k_categorias)' {c 123}}{p_end}
{phang2}{cmd:.     if `i'' != `r(ref_idx)'' di "rep78 = " `r(nombre_categoria_`i'')' ///}{p_end}
{phang2}{cmd:.        "  vs baseline p = " el(r(p_vsref), `i'', 1)}{p_end}
{phang2}{cmd:. {c 125}}{p_end}

{pstd}Reading the results back after the command runs -- the scalars and
matrices in {help svylet##results:Stored results} above:{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean)}{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. matrix list r(b)}{p_end}

{pstd}Reading the per-category letters and estimates programmatically,
one category at a time (this is exactly the pattern {helpb tsvy}
uses internally to build a table row by row):{p_end}
{phang2}{cmd:. forvalues i = 1/`r(k_categorias)' {c 123}}{p_end}
{phang2}{cmd:.     di "rep78 = " `r(nombre_categoria_`i'')' ///}{p_end}
{phang2}{cmd:.        "  estimate = " el(r(b), `i'', 1) ///}{p_end}
{phang2}{cmd:.        "  letter = " `r(letra_`i'')'}{p_end}
{phang2}{cmd:. {c 125}}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:svylet} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 26 2: Scalars}{p_end}
{synopt:{cmd:r(F_omnibus)}}omnibus Wald F-statistic (Korn-Graubard
adjusted); missing if not computable (see {cmd:r(k_categorias)} below){p_end}
{synopt:{cmd:r(p_omnibus)}}analytic p-value of the omnibus F-test{p_end}
{synopt:{cmd:r(p_omnibus_boot)}}bootstrap-calibrated p-value; missing
unless {cmd:boot()} was specified and at least one replication succeeded{p_end}
{synopt:{cmd:r(B_efectivo)}}number of {cmd:boot()} replications that
completed without error; missing if {cmd:boot()} was not specified{p_end}
{synopt:{cmd:r(df_num)}}numerator degrees of freedom of the omnibus test
({it:k}-1){p_end}
{synopt:{cmd:r(df_den)}}denominator degrees of freedom of the omnibus test
(Korn-Graubard adjusted){p_end}
{synopt:{cmd:r(df_raw)}}design degrees of freedom from {cmd:e(df_r)},
{it:unadjusted} -- use this one, not {cmd:r(df_den)}, if building an
ordinary {it:t}-based confidence interval by hand{p_end}
{synopt:{cmd:r(k_categorias)}}number of {cmd:over()} categories tested
({it:k}){p_end}
{synopt:{cmd:r(ref_idx)}}position (1,...,{it:k}) of {cmd:ref()} within
{cmd:over()}'s categories; 0 if {cmd:ref()} was not specified{p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 26 2: Macros}{p_end}
{synopt:{cmd:r(letra_}{it:i}{cmd:)}}Compact Letter Display code for the
{it:i}th category of {cmd:over()} ({cmd:?} if that category had
degenerate variance), {it:i} = 1,...,{it:k}{p_end}
{synopt:{cmd:r(nombre_categoria_}{it:i}{cmd:)}}value of {cmd:over()} that
the {it:i}th category corresponds to, {it:i} = 1,...,{it:k}{p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 26 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}{it:k} x 1: point estimate for each {cmd:over()}
category, in the same order as {cmd:r(nombre_categoria_}{it:i}{cmd:)}{p_end}
{synopt:{cmd:r(V)}}{it:k} x {it:k}: design-based variance-covariance
matrix of {cmd:r(b)}{p_end}
{synopt:{cmd:r(n_ponderado)}}{it:k} x 1: weighted sample size
({cmd:e(_N_subp)}) per category{p_end}
{synopt:{cmd:r(n_sin_ponderar)}}{it:k} x 1: unweighted sample size
({cmd:e(_N)}) per category{p_end}
{synopt:{cmd:r(ci_lower)}}{it:k} x 1: lower confidence limit per category,
read directly from {cmd:r(table)} of the underlying {cmd:svy:} call (in
the logit-transformed scale Stata itself uses for {cmd:proportion}, not
reconstructed by hand){p_end}
{synopt:{cmd:r(ci_upper)}}{it:k} x 1: upper confidence limit per category,
same source as {cmd:r(ci_lower)}{p_end}
{synopt:{cmd:r(p_vsref)}}{it:k} x 1: Bonferroni-adjusted ({it:k}-1
comparisons) p-value of each category against {cmd:ref()}'s category;
missing throughout if {cmd:ref()} was not specified, and at
{cmd:r(ref_idx)}'s own position always (a category is not tested against
itself){p_end}
{synopt:{cmd:r(p_vsref_raw)}}{it:k} x 1: same comparisons, raw (unadjusted)
p-value -- for audit/diagnostic use; apply your own correction if
{cmd:r(p_vsref)}'s plain Bonferroni is not what you want{p_end}
{p2colreset}{...}

{pstd}
{cmd:r(b)}, {cmd:r(V)}, {cmd:r(n_ponderado)}, {cmd:r(n_sin_ponderar)},
{cmd:r(ci_lower)}, and {cmd:r(ci_upper)} let a caller build a complete
point-estimate table (estimate, standard error via {cmd:sqrt(diag(r(V)))},
confidence interval, sample sizes) without running the underlying
{cmd:svy:} command a second time. {helpb tsvy} is built entirely on
these returns.


{marker references}{...}
{title:References}

{pstd}
Beran, R. 1988.
Prepivoting test statistics: A bootstrap view of asymptotic refinements.
{it:Journal of the American Statistical Association} 83(403): 687{c -}697.

{pstd}
Bretz, F., T. Hothorn, and P. Westfall. 2010.
{it:Multiple Comparisons Using R}. Boca Raton, FL: CRC Press.

{pstd}
Canty, A. J., and A. C. Davison. 1999.
Resampling-based variance estimation for labour force surveys.
{it:The Statistician} 48(3): 379{c -}391.

{pstd}
Davison, A. C., and D. V. Hinkley. 1997.
{it:Bootstrap Methods and Their Application}. Cambridge University Press.

{pstd}
Dunn, O. J. 1961.
Multiple comparisons among means.
{it:Journal of the American Statistical Association} 56(293): 52{c -}64.

{pstd}
Dunnett, C. W. 1955.
A multiple comparison procedure for comparing several treatments with a
control.
{it:Journal of the American Statistical Association} 50(272): 1096{c -}1121.

{pstd}
Dunnett, C. W. 1964.
New tables for multiple comparisons with a control.
{it:Biometrics} 20(3): 482{c -}491.

{pstd}
Field, C. A., and A. H. Welsh. 2007.
Bootstrapping clustered data.
{it:Journal of the Royal Statistical Society, Series B} 69(3): 369{c -}390.

{pstd}
Hall, P., and S. R. Wilson. 1991.
Two guidelines for bootstrap hypothesis testing.
{it:Biometrics} 47(2): 757{c -}762.

{pstd}
Hsu, J. C. 1996.
{it:Multiple Comparisons: Theory and Methods}. Boca Raton, FL: Chapman &
Hall/CRC.

{pstd}
Korn, E. L., and B. I. Graubard. 1990.
Simultaneous testing of regression coefficients with complex survey data:
Use of Bonferroni t statistics.
{it:The American Statistician} 44(4): 270{c -}276.

{pstd}
Rao, J. N. K., and C. F. J. Wu. 1988.
Resampling inference with complex survey data.
{it:Journal of the American Statistical Association} 83(401): 231{c -}241.

{pstd}
Rust, K. F., and J. N. K. Rao. 1996.
Variance estimation for complex surveys using replication techniques.
{it:Statistical Methods in Medical Research} 5(3): 283{c -}310.

{pstd}
Wolter, K. M. 2007.
{it:Introduction to Variance Estimation}. 2nd ed. Springer.


{marker author}{...}
{title:Author}

{pstd}
Andres Talavera Cuya. Affiliation stated for identification purposes
only -- this software is not an official product of INEI and INEI bears
no responsibility for it. Developed independently by the author; views,
methods, and results are the author's own and do not necessarily reflect
the position of INEI. Distributed under the GNU General Public License v3
(https://www.gnu.org/licenses/gpl-3.0.txt).

{pstd}
Source, installation instructions, and the companion command
{helpb tsvy}: {browse "https://github.com/atalaveracuya/svylet"}.
This is not (yet) an SSC package; download {cmd:svylet.ado} and this help
file into a directory on your {stata "adopath"} (or clone the repository
and add it with {cmd:adopath ++ <path>}).

{pstd}
Suggested citation: Talavera Cuya, A. 2026. svylet: Stata module to test
equality of survey-weighted means, totals, proportions, and ratios across
groups. Available from
{browse "https://github.com/atalaveracuya/svylet"}.


{marker also_see}{...}
{title:Also see}

{psee}
Online: {helpb tsvy}, {helpb svy}, {helpb svy postestimation},
{helpb mean}, {helpb total}, {helpb proportion}, {helpb test},
{helpb testparm}, {helpb pwcompare}, {helpb bsample}
{p_end}

{psee}
En espanol: {helpb svylet_es}
{p_end}
