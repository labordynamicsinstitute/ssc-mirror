{smcl}
{* *! version 3.0  26jul2026}{...}
{viewerjumpto "Syntax" "mmd_2s##syntax"}{...}
{viewerjumpto "Description" "mmd_2s##description"}{...}
{viewerjumpto "Options" "mmd_2s##options"}{...}
{viewerjumpto "Stored results" "mmd_2s##results"}{...}
{viewerjumpto "Methods and formulas" "mmd_2s##methods"}{...}
{viewerjumpto "Examples" "mmd_2s##examples"}{...}
{viewerjumpto "Author" "mmd_2s##author"}{...}
{title:Title}

{phang}
{bf:mmd_2s} {hline 2} Two-sample Maximum Mean Discrepancy (MMD) test, weight optional


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mmd_2s} {varname} {ifin} {weight}{cmd:,}
{cmdab:by:(}{varname}{cmd:)}
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{cmdab:by:(}{varname}{cmd:)}}grouping variable, must have exactly 2 distinct values{p_end}

{syntab:Optional}
{synopt:{cmdab:boot:(}{it:#}{cmd:)}}number of bootstrap replications; default {cmd:boot(200)}{p_end}
{synopt:{cmdab:reps:(}{it:#}{cmd:)}}number of independent draws averaged for the observed statistic; default {cmd:reps(1)}{p_end}
{synopt:{cmdab:seed:(}{it:#}{cmd:)}}sets the random-number seed via Mata {cmd:rseed()}; default uses current Stata seed{p_end}
{synopt:{cmd:boxplot}}draws an (unweighted) boxplot of {varname} by {cmd:by()} annotated with p-boot, effect size, and neff{p_end}
{synopt:{cmd:kdensity}}draws a (weighted, if applicable) kernel density plot of both groups{p_end}
{synopt:{cmdab:bw:(}{it:#}{cmd:)}}bandwidth for {cmd:kdensity}; default is the test's own sigma{p_end}
{synopt:{cmdab:npoints:(}{it:#}{cmd:)}}number of grid points for {cmd:kdensity}; default 200{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:aweight}s, {cmd:pweight}s, and {cmd:iweight}s are allowed; see {help weight}.
Weighting is entirely {bf:optional} -- omit {cmd:[weight]} for the unweighted test.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mmd_2s} tests the null hypothesis that two independent samples were
drawn from the same distribution, using a Maximum Mean Discrepancy (MMD)
statistic with an RBF (Gaussian) kernel and a bootstrap p-value.

{pstd}
{bf:Version 3.0 merges the former {cmd:mmd_2s} (unweighted) and
{cmd:mmd_2s_pond} (weighted) into a single command}, following the same
design as {help kstest:kstest.ado}: weighting is specified with Stata's
{bf:native} {cmd:[pweight/aweight/iweight]} syntax, not a separate
required option. When no weight is specified, an internal weight of 1
is used for every observation, and the command reproduces the old
unweighted {cmd:mmd_2s} v1.0 exactly (to machine precision, same
{cmd:seed()}/{cmd:boot()}/{cmd:reps()}). There is no longer a separate
{cmd:mmd_2s_pond} file to keep in sync -- one codebase, one set of Mata
functions, weight defaults to 1.

{pstd}
The underlying estimator is the linear-time / paired-subsample MMD
(Gretton-style): random pairs are drawn within each group, a four-term
RBF kernel combination is computed per pair, and the (optionally
weighted) average across pairs is the statistic, clipped at 0 and
averaged over three bandwidths (sigma/2, sigma, 2*sigma). When weights
are supplied, {bf:which} observations are paired is still chosen
uniformly at random; the weight only affects {bf:how much} a given pair
counts in the average (see {help mmd_2s##methods:Methods and formulas}).
This is a deliberate design choice suited to the paired-subsample
estimator, and is {bf:not} the same normalization pattern used by
{help kstest:kstest} (which weights each group's full empirical CDF by
its own total weight) -- the two commands weight in structurally
different ways appropriate to their respective statistics.


{marker options}{...}
{title:Options}

{phang}
{cmdab:by:(}{varname}{cmd:)} {it:(required)} specifies the grouping
variable. It must take exactly two distinct values in the estimation
sample (after excluding missing {cmd:by()}, which is done automatically);
the command exits with an error otherwise.

{phang}
{it:{help weight}} ({cmd:aweight}/{cmd:pweight}/{cmd:iweight}) is
{it:optional}. If specified, non-positive or missing weight values are
excluded from the sample automatically (same treatment as missing
{cmd:by()}). If omitted, every observation gets weight 1.

{phang}
{cmdab:boot:(}{it:#}{cmd:)} number of bootstrap replications used to
build the null distribution (resampling with replacement from the
pooled sample; weights travel with each row). Default 200; increase for
finer p-value resolution (minimum detectable p-value is 1/(boot+1)).

{phang}
{cmdab:reps:(}{it:#}{cmd:)} number of independent draws averaged to form
the observed MMD statistic. Because the estimator subsamples the data, a
single draw can be noisy, especially with small effective sample size.
{cmd:reps(1)} (default) reproduces a single-draw statistic;
{cmd:reps(20)} or higher is recommended for production use. When
{cmd:reps(#)>1}, {cmd:r(mmd_stat_sd)} reports the draw-to-draw standard
deviation as a stability diagnostic.

{phang}
{cmdab:seed:(}{it:#}{cmd:)} sets the Mata seed via {cmd:rseed()} before
any resampling, for reproducibility. If omitted, the current Mata random
state is used.

{phang}
{cmd:boxplot} draws a {cmd:graph box} of {varname} over {cmd:by()} (the
boxplot itself is unweighted -- visual aid only), annotated with p-boot,
effect size, and neff of both groups.

{phang}
{cmd:kdensity} draws kernel density curves for both groups, weighted if
a weight was specified, with bandwidth anchored to the test's own sigma
unless {cmd:bw()} overrides it.


{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(mmd_stat)}}observed MMD statistic (average of {cmd:reps()} draws){p_end}
{synopt:{cmd:r(mmd_stat_sd)}}SD across {cmd:reps()} draws (missing if {cmd:reps(1)}){p_end}
{synopt:{cmd:r(mmd_boot_mean)}}mean of the bootstrap null distribution{p_end}
{synopt:{cmd:r(p_boot)}}bootstrap p-value, {cmd:(#(boot>=stat)+1)/(boot()+1)} (Davison-Hinkley "+1" correction -- never exactly 0){p_end}
{synopt:{cmd:r(effect_size)}}{cmd:mmd_stat / mmd_boot_mean}{p_end}
{synopt:{cmd:r(nA)} / {cmd:r(nB)}}raw sample size, each group{p_end}
{synopt:{cmd:r(neff_A)} / {cmd:r(neff_B)}}Kish effective sample size (= raw n if unweighted){p_end}
{synopt:{cmd:r(sigma)}}RBF kernel bandwidth (median heuristic){p_end}
{synopt:{cmd:r(N_boot)} / {cmd:r(N_reps)}}number of replications/draws used{p_end}
{p2colreset}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(weighted)}}{cmd:"yes"} or {cmd:"no"}{p_end}
{p2colreset}{...}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Effective sample size:} n_eff = (sum w)^2 / sum(w^2) (Kish, via
Monahan 2011, eq. 12.4.5). Reduces to raw n when w=1 for all.

{pstd}
{bf:MMD statistic (single draw):} let m = floor(min(neff_A,neff_B)/2).
Draw 2m indices {bf:uniformly at random} (without replacement) from each
group, split into two halves, form h = k(x1,x2)+k(y1,y2)-k(x1,y2)-k(x2,y1)
with an RBF kernel. The statistic is the {bf:weighted average of h}
using per-pair weights w_par=(wx1*wx2+wy1*wy2)/2, floored at 0. Note
this weights the {it:contribution} of each already-uniformly-selected
pair -- it does not make high-weight observations more likely to be
selected into a pair. Repeated at bandwidths sigma/2, sigma, 2*sigma and
averaged, then averaged again over {cmd:reps()}.

{pstd}
{bf:Bandwidth (sigma):} median of pairwise absolute differences on the
pooled variable; if pooled n>2000, a subsample of 2000 is drawn first
(weighted, without replacement, Efraimidis-Spirakis) -- with n<=2000 the
result does not depend on weights at all.

{pstd}
{bf:Bootstrap:} pooled sample (values and weights together) resampled
with replacement {cmd:boot()} times; same statistic recomputed each
time. p-value = (# replicates >= observed + 1) / (boot() + 1).


{marker examples}{...}
{title:Examples}

{pstd}Unweighted (no {cmd:[weight]} specified){p_end}
{phang2}{cmd:. mmd_2s wage, by(union) boot(200) seed(12345)}{p_end}

{pstd}
{bf:Real-data example, weighted, with public microdata}: harvested
surface area, transitory vs. permanent crops, using Peru's national
agricultural survey (ENA). Data downloaded directly from the official
INEI microdata portal with the companion command {help sriinei:sriinei}
(also available on SSC) -- no data files are distributed with this
package.{p_end}
{phang2}{cmd:. sriinei, codigo(1036) modulo(1895) tipo(csv) destino("C:\BD_INEI\mic")}{p_end}
{phang2}{cmd:. cd "C:\BD_INEI\mic\1036-Modulo1895"}{p_end}
{phang2}{cmd:. use 03_CAP200AB, clear}{p_end}
{phang2}{cmd:. keep if codigo==1 & inlist(p204_tipo,1,2)}{p_end}
{phang2}{cmd:. gen sup_cosechada=p217_sup_ha}{p_end}
{phang2}{cmd:. drop if missing(sup_cosechada, factor)}{p_end}
{phang2}{cmd:. gen double sup_cosechada_log = log(sup_cosechada + 1)}{p_end}
{phang2}{cmd:. mmd_2s sup_cosechada_log [aweight=factor], by(p204_tipo) boot(30) reps(20) kdensity}{p_end}


{marker author}{...}
{title:Author / development notes}

{pstd}
{cmd:mmd_2s} v3.0 merges the former {cmd:mmd_2s}/{cmd:mmd_2s_pond} pair
into a single command, adopting the weight-optional design of
{help kstest:kstest.ado} (Ariel Linden). See also
{help sriinei:sriinei}, a companion command for downloading public
microdata directly from an official statistics portal (used in the
real-data example above).

{pstd}
Andres Talavera Cuya{break}
Direccion Nacional de Censos y Encuestas -- INEI Peru{break}
Junio 2026

{hline}
{title:License}

{pstd}
This module is made available under the terms of the GPL v3
({browse "https://www.gnu.org/licenses/gpl-3.0.txt":https://www.gnu.org/licenses/gpl-3.0.txt}).

{hline}
{title:Version}

{pstd}
{bf:mmd_2s} v3.0 -- 26jul2026
