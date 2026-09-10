{smcl}
{* *! finegray methods and formulas}{...}
{vieweralsosee "finegray" "help finegray"}{...}
{vieweralsosee "finegray_predict" "help finegray_predict"}{...}
{vieweralsosee "finegray_cif" "help finegray_cif"}{...}
{vieweralsosee "finegray_phtest" "help finegray_phtest"}{...}
{vieweralsosee "[ST] stcrreg" "help stcrreg"}{...}
{vieweralsosee "[ST] stcox" "help stcox"}{...}
{viewerjumpto "Description" "finegray_methods##description"}{...}
{viewerjumpto "The estimator" "finegray_methods##estimator"}{...}
{viewerjumpto "Variance" "finegray_methods##variance"}{...}
{viewerjumpto "The nuisance term" "finegray_methods##nuisance"}{...}
{viewerjumpto "What is refused, and why" "finegray_methods##refusals"}{...}
{viewerjumpto "Three kinds of strata" "finegray_methods##strata"}{...}
{viewerjumpto "Baseline strata" "finegray_methods##bstrata"}{...}
{viewerjumpto "Time-varying effects" "finegray_methods##tvc"}{...}
{viewerjumpto "Left truncation" "finegray_methods##lt"}{...}
{viewerjumpto "Weight support boundaries" "finegray_methods##boundary"}{...}
{viewerjumpto "Factor variables and margins" "finegray_methods##fv"}{...}
{viewerjumpto "Multiple imputation" "finegray_methods##mi"}{...}
{viewerjumpto "Cumulative incidence" "finegray_methods##cif"}{...}
{viewerjumpto "Proportionality diagnostic" "finegray_methods##phtest"}{...}
{viewerjumpto "Comparison with stcrreg" "finegray_methods##stcrreg"}{...}
{viewerjumpto "Performance" "finegray_methods##performance"}{...}
{viewerjumpto "Citation scope" "finegray_methods##citation"}{...}
{viewerjumpto "References" "finegray_methods##references"}{...}
{viewerjumpto "Author" "finegray_methods##author"}{...}
{title:Title}

{p2colset 5 27 29 2}{...}
{p2col:{cmd:finegray_methods} {hline 2}}Methods, formulas and design rationale for {cmd:finegray}{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
This file holds the methods, formulas, grounding and design rationale behind
{helpb finegray} and its post-estimation commands. It documents no command and
has no syntax of its own. Everything you type is documented in
{helpb finegray}, {helpb finegray_predict}, {helpb finegray_cif} and
{helpb finegray_phtest}; each option there carries an operational description,
its default, and its return code when refused, plus a link to the section here
that explains why.

{pstd}
The question this file answers most often is why {cmd:finegray} refuses a
combination of options rather than returning a plausible number for it. The
estimator is grounded in published derivations, and a cell with no derivation
behind it is an error rather than a default. The refused cells are collected in
{help finegray_methods##refusals:What is refused, and why}.


{marker estimator}{...}
{title:The estimator}

{pstd}
The Fine-Gray model directly models the subdistribution hazard, which is the
instantaneous rate of failure from the cause of interest among subjects who
have not yet experienced that specific cause. Subjects who experience a
competing event remain in the risk set indefinitely with time-dependent weights
derived from the Kaplan-Meier estimate of the censoring distribution.

{pstd}
A subdistribution hazard ratio (SHR) greater than 1 indicates that the
covariate increases the cumulative incidence of the cause of interest. Unlike
cause-specific hazard ratios, SHRs have a direct interpretation in terms of the
cumulative incidence function.

{pstd}
{bf:Computation.} The estimator uses a native forward-backward scan
adapted from Kawaguchi et al. (2021) that avoids expanding the data over
event times. Their published decomposition covers right-censored data
without ties; tie handling, delayed entry, baseline stratification and the
variance extensions are package extensions rather than theirs. See
{help finegray_methods##citation:Citation scope} for what each source does
and does not ground.

{pstd}
{bf:Identification.} Because the subdistribution pseudo-likelihood is evaluated
only over cause-event risk sets, a covariate can be of full rank in the data as
a whole and still contribute no information to the fit -- for example, if it is
nonzero only for subjects censored before the first cause event. Such a
coefficient is not estimable, so {cmd:finegray} names the offending term and
stops rather than reporting an arbitrary value for it. Constant and exactly
collinear covariate columns are refused the same way with {cmd:r(459)}; the
command does not silently impose a ridge penalty.

{pstd}
{bf:Convergence.} Convergence is declared when the Newton decrement,
{cmd:score' * inv(I) * score}, falls below {opt tolerance()}. Near the
optimum this is approximately twice the remaining gain in the log
pseudo-likelihood. The decrement is used rather than the size of the
coefficient step because it is invariant to rescaling a covariate, so
{cmd:x} and {cmd:1e6*x} converge to the same fit.

{pstd}
{bf:A nonconverged fit is reported, not suppressed.} {cmd:finegray} prints the
last iterate with {cmd:e(converged)} set to 0 and a warning above the
coefficient table. Those coefficients are not a solution, and every quantity
downstream is a function of the solution, so {helpb finegray_predict},
{helpb finegray_cif} and {helpb finegray_phtest} all exit with {cmd:r(430)}
rather than return a number computed at a non-solution with
{cmd:rc = 0}. Refits inside a {opt bootstrap()} option are a separate
matter: those are skipped and counted rather than treated as fatal.


{marker variance}{...}
{title:Variance}

{pstd}
{bf:Scope of the sandwich estimator.} The default sandwich is a
{it:fixed-weight} sandwich: it treats the estimated
inverse-probability-of-censoring weights as fixed and does not propagate
the uncertainty in the estimated censoring distribution G(t) (nor, under
delayed entry, the entry distribution H(t)). Under right censoring this is
the same variance convention {helpb stcrreg}
reports. {bf:Same convention is not the same digits:} the two commands
break ties in the censoring Kaplan-Meier differently, so the standard
errors agree to about four significant figures rather than exactly: the
coefficients agree to numerical precision, the standard errors only to the
tie convention. A comparison against {cmd:stcrreg} should therefore be read
as agreement to a tolerance, not as equality. Under delayed entry the commands
use different weights, so neither estimates nor standard errors are
numerically comparable. Coefficients are unaffected by the variance option
-- only their standard errors change.

{pstd}
{bf:Why model-based standard errors are not the default, and are not}
{bf:generally valid.} The weighted Fine-Gray estimating equation is a
pseudo-likelihood score, so the ordinary likelihood information identity need
not hold: inverse information omits the empirical score variability and any
estimated-weight contribution. It can coincide with a likelihood variance in
special limiting cases, but model-based standard errors are generally too small
in the competing-risk settings targeted here, and their confidence intervals
need not have nominal coverage. {opt norobust} exists so that the naive
likelihood variance can be inspected and compared; use the default sandwich
variance to report results, and note that {cmd:finegray} prints a warning
whenever {opt norobust} is used.

{pstd}
{bf:Under delayed entry, inverse information also omits weight-estimation}
{bf:uncertainty.} Bellach et al. (2020, sec. 5) document truncation-dependent
undercoverage of inverse-information inference. Do not use {opt norobust} for
inference on left-truncated data.

{pstd}
{bf:Clustering.} {opt cluster()} fits the marginal (population-average)
proportional subdistribution hazards model of Zhou, Fine, Latouche and Labopin
(2012), whose sandwich sums the influence functions {it:within} cluster before
squaring them (their sec. 2.3, p. 376); with one subject per cluster it reduces
exactly to Fine and Gray (1999). The clustered variance matrix is a sum of
{it:g} cluster-score
outer products whose totals sum to zero at the solution, so its rank is at most
{it:g}-1. {cmd:finegray} therefore requires more clusters than coefficients and
errors out otherwise, rather than reporting standard errors that the g-inverse
invented for directions the variance matrix cannot see. {opt cluster()} is not
allowed with {opt norobust} because the former requests a cluster-robust
sandwich and the latter requests an inverse-information variance.

{pstd}
{bf:Scope of the Zhou et al. (2012) grounding.} That paper treats clustered
{it:right-censored} data with a pooled marginal censoring estimate. Two
supported combinations lie outside it: {opt cluster()} under delayed entry, and
{opt cluster()} with {opt strata()}, which makes the censoring estimate
group-stratified. In both, {cmd:finegray} applies the same within-cluster
influence-function summation, but the extension is by construction rather than
by published derivation; treat clustered delayed-entry and clustered stratified
standard errors as an implementation of the natural extension, not as a result
established in the cited literature.

{pstd}
{bf:Bootstrap coefficient inference.} The {opt bootstrap()} options of
{helpb finegray_cif} and {helpb finegray_predict} resample subjects to get
{it:CIF} and {it:prediction} standard errors; they do {bf:not} produce
nuisance-adjusted standard errors for the coefficient vector {cmd:e(b)}. For
coefficient-level inference that accounts for estimating G(t) -- and H(t) under
delayed entry -- bootstrap the whole fit by resampling subjects and
re-estimating in each replication. Each replication then re-estimates the
model and, under delayed entry, G(t), H(t) and the weight strata, so the
resulting standard errors propagate the weight-estimation uncertainty the
fixed-weight sandwich omits. The worked wrapper is in
{help finegray##vcebootstrap:Options} in {helpb finegray}; use enough
replications (500+) for a stable standard error.


{marker nuisance}{...}
{title:The nuisance term}

{pstd}
{opt nuisance} adds the Fine and Gray (1999, eq. 7-8, pp. 500-501) {it:psi}
term to the sandwich meat, so that the meat becomes sum_i (eta_i + psi_i)^2
rather than sum_i eta_i^2. The {it:eta} term is the score contribution treating
the censoring survivor G as known; {it:psi} is the additional contribution from
having {bf:estimated} G by Kaplan-Meier. With {opt nuisance},
{cmd:finegray}'s variance targets the same right-censoring nuisance-adjusted
sandwich as {cmd:cmprsk::crr}.

{pstd}
The correction is not always conservative: {it:eta} and {it:psi} are
correlated, so the nuisance-adjusted variance can be larger or smaller than the
default. It is therefore not safe to assume the default is the "conservative"
choice. {opt nuisance} is not the default, so upgrading does not move standard
errors reported from earlier releases.

{pstd}
{bf:How it composes.} Under {opt bstrata()} the psi term is Zhou
et al.'s (2011, sec. 4.1) Sigma_rk, that is, eq. (7)-(8) computed within
stratum, which is what {cmd:crrSC::crrs} computes under {cmd:ctype=1}. Under
{opt tvc()}, psi is a linear functional of a score that decomposes exactly over
intervals, so it decomposes with it.

{pstd}
{bf:Under delayed entry.} Fine and Gray's psi is the influence of the
censoring Kaplan-Meier, and the Weight-1 stabilizer is not a censoring
Kaplan-Meier: it is A(t) = b(t)/S(t-), the observed at-risk fraction over the
left-truncated all-cause survival (Zhang, Zhang and Fine 2011, eq. 5). Their
Appendix B (pp. 1944-1945) writes the i.i.d. representation of the score as
three terms, W_i = l_i + v_i + w_i: l_i is the fixed-weight score residual
("the main term"), v_i the influence of the estimated S through the all-cause
martingale, and w_i the influence of the estimated b through the exact
indicator form of an empirical average. {opt nuisance} on a delayed-entry fit
adds v_i + w_i, computed against the package's own fitted weights: Gate
Z-ties established that the product form G(t-)H(t-) the engine holds
reproduces b/S(t-) on every collision class under the events, then
censorings, then entries tie ordering, so the appendix's terms apply to the
weights actually used. Without delayed entry b/S(t-) is G(t-) itself, and the three-term
representation converges to Fine and Gray's eta+psi as n grows -- converges,
not coincides: the appendix's w_i is the exact influence of an empirical
average where eq. (8) uses the martingale linearization, and the two agree only
asymptotically. Right-censored fits keep eq. (7)-(8) unchanged. The term is available
for the {bf:pooled} weight only: for the stratified weight (their eq. 7) ZZF's
Appendix E (p. 1949) estimate the variance "treating the weight function
known", which is the default sandwich, so {opt nuisance} with {opt strata()}
or {opt truncstrata()} under delayed entry is refused ({cmd:r(198)}) rather
than approximated. The three candidate variances differ in what they treat
as known: {cmd:model_based} treats the pseudo-likelihood as a likelihood,
{cmd:fixed_weight_sandwich} treats the estimated weights as fixed, and
{cmd:nuisance_adjusted} additionally propagates the uncertainty in the
estimated censoring (and, under delayed entry, entry) distribution. Only the
latter two are consistent for the sandwich meat of a weighted estimating
equation, and the model-based form is not generally valid for it, which is why
the shipped default is {cmd:fixed_weight_sandwich} and {opt nuisance} is an
opt-in defined for the pooled weight alone. The package's QA suite, which is
distributed with the source in the
{browse "https://github.com/tpcopeland/Stata-Tools":Stata-Tools repository} and
not with the installed package, includes a simulation study of the Wald
coverage of each candidate.

{pstd}
{bf:Why it stops at the coefficients.} {helpb finegray_cif} and
{helpb finegray_predict} use a fixed-weight analytic CIF influence function,
including on a {opt tvc()} fit, whose piecewise form is derived. The full CIF
influence function includes the coefficient-path {it:psi} contribution and a
separate weight-estimation contribution for the baseline/CIF path. The analytic
post-estimation path includes neither contribution and remains fixed-weight, so
its standard errors are identical after a {opt nuisance} fit and after a default
fit. {cmd:r(se_method)} records which route produced an interval, and those
commands' {opt bootstrap()} options are how a CIF interval comes to include
weight re-estimation.


{marker refusals}{...}
{title:What is refused, and why}

{pstd}
{cmd:finegray} refuses an unsupported combination rather than accepting it as a
no-op or answering it from a derivation that does not cover it. An option that
quietly does nothing is indistinguishable from one that worked, and a number
returned outside its derivation is wrong at {cmd:rc = 0}. Each refusal below is
documented at its own option in {helpb finegray} with the return code it
raises; this section is the reasoning.

{pstd}
{bf:Three cells on the delayed-entry branch}, all {cmd:r(198)}, and each for
its own reason rather than one shared one:

{p2colset 9 34 36 2}{...}
{p2col:{opt nuisance} + delayed entry + weight strata}the pooled-weight term
(Zhang, Zhang and Fine 2011, Appendix B) is implemented; for the stratified
weight their own Appendix E ships the first part only, "treating the weight
function known", which is the default sandwich. A stratified nuisance term
would be a package invention, so the cell is refused rather than
approximated{p_end}
{p2col:{opt bstrata()} + delayed entry}the stratified
subdistribution papers used here cover right censoring; this package does not
implement a stratified-baseline delayed-entry extension{p_end}
{p2col:{opt tvc()} + delayed entry}no source for time-varying subdistribution
coefficients under left truncation at all, and the delayed-entry branch is
already this package's own extension{p_end}
{p2colreset}{...}

{pstd}
{bf:Design-weight cells}, all {cmd:r(198)}: {cmd:pweight} + {opt norobust},
weights + {opt nuisance}, weights + {opt strata()}/{opt truncstrata()},
weights + {opt bstrata()}, weights + {opt tvc()}, weights + delayed entry,
and {helpb finegray_phtest} after a weighted fit. The reasoning for each is
in {help finegray_methods##weights:Design weights}.

{pstd}
{bf:An option that would do nothing.} {opt truncstrata()} on data with no
delayed entry is {cmd:r(198)}, not an accepted no-op. So is a {opt tvc()}
variable that names no coefficient in the model, {opt tsplit()} without
{opt tvc()} or the reverse, {opt attime()} after a fit that has no
time-varying coefficient to evaluate, {opt timevar()} alongside {opt xb} or
{opt schoenfeld}, and {opt ci} alongside {opt basecshazard} -- the last because
a silently ignored {opt ci} would hand back a bare point estimate that looks
like a band.

{pstd}
{bf:A quantity that is not identified.} A {opt tvc()} interval with no
cause-of-interest event is {cmd:r(459)} naming the interval: its
coefficients are not identified, and silently omitting an interval would
change the model without saying so. {cmd:ibn.} as a {it:main effect} names
every level, and the Fine-Gray partial likelihood has no intercept to
absorb the redundancy, so adding a constant to every level's coefficient
leaves the likelihood unchanged and one level is not
identified; {cmd:finegray ibn.grp ...} therefore stops with {cmd:r(459)}
and tells you to use {cmd:i.} or {cmd:ib}{it:#}{cmd:.} instead. It does
not silently drop a level and report the rest, which is what {helpb stcox}
does with the same specification. {cmd:ibn.} inside an interaction
({cmd:c.x#ibn.grp}) is estimable and is accepted.

{pstd}
{bf:An outcome classification that is missing.} {opt compete()} is the outcome
classification, not a covariate, so it must be observed on every record of the
estimation sample. A record whose event type is {it:missing} is refused with
{cmd:r(198)} rather than dropped: dropping it would remove an event from the
estimand with nothing on screen, and it would be inconsistent with the check
that already refuses a record whose event type merely {it:disagrees} with the
{cmd:stset} failure indicator.

{pstd}
{bf:A curve that is degenerate rather than estimated.} A baseline stratum with
no cause-of-interest event has a Breslow estimator that is identically zero. A
flat CIF at exactly 0 for a whole group reads as a finding, so
{cmd:predict, cif}, {cmd:predict, basecshazard} and {helpb finegray_cif} refuse
that stratum with {cmd:r(459)} rather than draw it. The fit itself proceeds --
the stratum's terms drop out of the pseudo-likelihood -- with a note naming the
level and {cmd:e(bstrata_noevent)} recording it.

{pstd}
{bf:A design the model was never fitted to.} The package-owned {cmd:_fg_*}
design columns may be {it:dropped} freely, because every post-estimation
command rebuilds them on demand from the expansion recorded at estimation. One
that is still present but has been {it:altered} is {cmd:r(459)}, because the
fitted coefficients no longer correspond to what the column holds and the
answer would otherwise be computed against a different design at
{cmd:rc = 0}. The same reasoning drives the {cmd:e(datasignature)} check on
every path that reconstructs an influence function or a risk set.


{marker strata}{...}
{title:Three kinds of strata}

{pstd}
Three different things are called "strata" in this package, and they are three
different options. Only {opt bstrata()} means what {cmd:stcox}'s {cmd:strata()}
means. {helpb stcrreg} has no stratification option at all, so there is no
established competing-risks convention to follow.

{synoptset 18 tabbed}{...}
{synopt:{cmd:bstrata()}}the baseline subhazard -- what {cmd:stcox, strata()} means{p_end}
{synopt:{cmd:strata()}}the Kaplan-Meier censoring distribution G{p_end}
{synopt:{cmd:truncstrata()}}the entry (left-truncation) distribution H{p_end}
{synoptline}

{pstd}
The axes are independent and compose. {cmd:bstrata(centre) strata(centre)}
frees the baseline by centre {it:and} estimates G within centre; that pairing is
the regularly-stratified regime of Zhou et al. (2011) sec. 3.2, and is
{cmd:crrSC::crrs}'s {cmd:ctype = 1}. {cmd:bstrata(centre)} alone frees the
baseline while pooling G, which is {cmd:crrs}'s {cmd:ctype = 2}. Both mappings'
coefficients are cross-validated against {cmd:crrs} in the package's
cross-validation suite.

{pstd}
{opt strata()} and {opt truncstrata()} are specified independently and are
cross-classified internally into joint weight cells; {cmd:finegray} never
silently reuses {opt strata()} for the entry distribution. The boundaries on
how finely those cells may be cut are in
{help finegray_methods##boundary:Weight support boundaries}.


{marker bstrata}{...}
{title:Baseline strata}

{pstd}
{opt bstrata(varname)} fits Zhou, Latouche, Rocha and Fine's (2011) stratified
proportional subdistribution hazards model,

{pmore2}
lambda_1k(t | Z) = lambda_1k0(t) exp(Z'b),   k = 1, ..., K,

{pstd}
one unconstrained baseline subdistribution hazard per level of {it:varname},
one shared coefficient vector. No assumption is made about how the baselines
relate to each other. The log pseudo-likelihood is a sum of independent
within-stratum terms, so the score and the information are sums too, and every
risk set -- including the retained competing-event subjects the Fine-Gray
weights keep in it -- is formed {it:inside} the stratum.

{pstd}
{bf:When to reach for it.} A discrete factor whose subdistribution hazards are
clearly non-proportional cannot be handled by putting it in {it:varlist}: the
model would report a hazard ratio that does not exist. Stratifying on it
adjusts for it without estimating its effect. The cost is that the factor gets
no coefficient and no test, so this is for nuisance structure -- centre, era,
registry -- not for the exposure you came to study. A multicentre study whose
centres have different baseline incidence is the motivating case.

{pstd}
{bf:Scope: right censoring only.} {opt bstrata()} with delayed entry is refused
with {cmd:r(198)}. Zhou et al. (2011) is a right-censoring paper -- entry times
appear nowhere in it -- and neither does Zhang, Zhang and Fine (2011) treat
baseline stratification. This package does not implement or validate their
combination. Kim et al. (2020, sec. 7) discuss further work for case-cohort
left-truncated data when independent truncation may fail; that statement is
not a general impossibility claim about stratified delayed-entry models.

{pstd}
{bf:Variance.} The reported standard errors are the package's usual
subject-level sandwich, with the score residuals now formed within stratum and
summed across subjects as before; it is consistent for a {it:fixed} number of
strata as the strata grow. Two things follow.

{phang2}
Zhou et al. (2011) sec. 4.1 gives the regularly-stratified variance as
Sigma_rk = E{(eta_ki + psi_ki)^2}, that is, Fine and Gray's (1999) eq. 7-8
{it:within stratum k}, including the psi term for having estimated G. The
default remains the eta-only (fixed-weight) part, exactly as it is without
{opt bstrata()}; {opt nuisance} adds the stratified psi and makes the reported
variance the paper's. {cmd:bstrata(}{it:v}{cmd:) strata(}{it:v}{cmd:)} is
{cmd:crrs}'s {cmd:ctype=1} -- G estimated within stratum -- and that cell is
cross-validated against {cmd:crrs} directly. {cmd:bstrata(}{it:v}{cmd:)}
{it:without} {opt strata()} is a stratified baseline with a {bf:pooled} G,
which {cmd:crrs} has no counterpart for: its {cmd:ctype=2} is the
highly-stratified variance of sec. 4.2, a different derivation. That cell is
this package's own composition of Zhou's additivity over strata with Fine and
Gray's eq. (8), and it is validated by simulation rather than against an
external implementation.

{phang2}
Zhou et al. (2011) sec. 4.2 records that the closed-form stratified variance
"can be unstable in small sample sizes, owing to variability in Ghat in the
tails and the small within cluster sample sizes", and their remedy is a
stratum-level bootstrap. {cmd:finegray} implements no stratum-level
bootstrap. With many small strata, treat the reported standard errors with
caution and bootstrap the whole fit for coefficient inference.

{pstd}
{bf:The highly-stratified regime is out of scope.} Zhou et al. distinguish
{it:regularly} stratified data (a few large strata) from {it:highly} stratified
data (many small ones). The estimating equation is the same in both; the
asymptotics, the variance derivation, and the availability of a baseline are
not. In the highly-stratified regime the paper states the baseline cumulative
subdistribution hazard is "infeasible" and the cumulative incidence cannot be
predicted at all. {cmd:finegray} implements the regular regime: it always
reports a per-stratum baseline and always lets you ask for a CIF. Nothing in
the command detects which regime your data are in, so that judgement is yours.

{pstd}
{bf:Why {helpb finegray_cif} requires {opt bstratum(#)}.} Once the baselines
are free, a covariate profile no longer identifies a curve -- the same
{opt at()} has {it:K} of them. Choosing one silently would report one of {it:K}
answers with nothing on screen to say which. {opt over()} on the
{opt bstrata()} variable is the other honest answer: all {it:K} curves, each
labelled. A stratum-{it:averaged} CIF is a
different estimand: it needs declared stratum weights, and it is not
implemented.

{pstd}
{bf:Cost.} The scan runs once per stratum over that stratum's rows, so it stays
linear in {it:n} and the package's scaling is unchanged; what {it:K} adds is a
constant factor, from selecting each stratum's rows out of the global time
order. Measured on simulated competing-risks data with two covariates, against
the same fit without {opt bstrata()}: 1.1x at {it:K} = 4, 1.4-1.6x at
{it:K} = 20, and 2.1-2.4x at {it:K} = 100, essentially unchanged between
{it:n} = 50,000 and {it:n} = 200,000 (6.6 s pooled, 7.2 s at {it:K} = 4 and
15.7 s at {it:K} = 100 for {it:n} = 200,000). The large-{it:K} end of that
range is the highly-stratified regime this version does not claim to cover
anyway.

{pstd}
{bf:With one level} {opt bstrata()} is the unstratified estimator, bit for bit
-- same {cmd:e(b)}, {cmd:e(V)}, {cmd:e(ll)} and {cmd:e(basehaz)}. That identity
is asserted rather than assumed.


{marker tvc}{...}
{title:Time-varying effects}

{pstd}
{opt tvc(varlist)} with {opt tsplit(numlist)} fits a proportional
subdistribution hazards model whose coefficient on the named covariates is
piecewise constant in analysis time,

{pmore2}
lambda_1(t | Z) = lambda_10(t) exp(Z'b(t)),   b(t) = b_j for t in interval j,

{pstd}
with {it:J} intervals defined by the {it:J} - 1 interior boundaries in
{opt tsplit()}. Every named covariate gets {it:J} free coefficients; every
other covariate keeps one. There is still exactly one baseline subdistribution
hazard -- the interval structure lives in the linear predictor, not in
lambda_10.

{pstd}
{bf:Grounding.} This is the estimator of Fine and Gray (1999), not an extension
of it. That paper's model takes {it:Z} to be a bounded covariate vector and
explicitly admits deterministic functions {it:Z}({it:t}) of the baseline
{it:Z} and {it:t} -- covariate-by-time interactions (sec. 2, pp. 497-498) --
and the paper's own data analysis uses them, fitting treatment-by-{it:t} and
treatment-by-{it:t}-squared terms after finding "substantial lack of fit" in
the proportional model (sec. 7, p. 503). An interval indicator is such a
deterministic function. What is new here is only the {it:computation}: the
piecewise design is fitted without expanding the data into episodes. The same
model is available in {helpb stcrreg} as {cmd:tvc()} with an indicator
{cmd:texp()}, and the two agree -- {cmd:finegray, tvc(x) tsplit(}{it:c}{cmd:)}
is pinned against {cmd:stcrreg, tvc(x) texp(_t > }{it:c}{cmd:)}.

{pstd}
{bf:Time-varying effects are not time-varying covariates}, and the difference
is not a technicality. {opt tvc()} changes the {it:coefficient} on a covariate
whose value is fixed at baseline; the risk set, the subdistribution weights and
the cumulative incidence are all still well defined, because {it:Z} is known
for every subject at every time -- including after a competing event, when the
subject is retained in the Fine-Gray risk set. An {it:internal} time-varying
covariate is not known there: the subject has failed from another cause, and
its covariate path has no meaning after that. {cmd:finegray} refuses records
whose covariates vary within {cmd:id()} for that reason, and {opt tvc()} does
not change it. Bellach et al. (2019) ground that limitation. See
{helpb stcox} for a cause-specific model when internal time-varying covariates
are scientifically appropriate.

{pstd}
{bf:Why intervals are half-open at the left.} Interval {it:j} is
({it:cut_j-1}, {it:cut_j}], with {it:cut_0} = 0 and the last interval open on
the right, so an event exactly at a boundary belongs to the earlier
interval. That is the {cmd:(}{it:t0}{cmd:,} {it:t}{cmd:]} convention every risk
set in this command uses, and it is what lets every baseline lookup downstream
stay an ordinary "largest event time at or before {it:s}" search. The
convention is pinned by a test with an event placed exactly on a boundary.

{pstd}
{bf:Why the equation names are plain.} Coefficients arrive in equations
{cmd:main}, {cmd:tvc1} ... {cmd:tvc}{it:J}. Something like {cmd:5 < _t <= 10}
reads better but breaks {cmd:[}{it:eqname}{cmd:]} parsing, so
{cmd:test [tvc1]x = [tvc2]x} -- the Wald test of whether the effect is in fact
constant, which is most of the reason to fit the model -- would fail
{cmd:r(132)}. Separate coefficients per interval, rather than a main effect
plus offsets, are what make that a one-line test.

{pstd}
{bf:Why there is no smooth {cmd:texp()}.} Every scan in this package is
linear-time because exp({it:Z}'b) is constant within an interval and can be
computed once. A continuous function of {it:t} in the linear predictor destroys
that for every risk set, and a slow path is not something this package ships
quietly.

{pstd}
{bf:Why some post-estimation is withdrawn.} {cmd:finegray_predict}'s {opt xb},
{opt cif} and {opt basecshazard} are available after a {opt tvc()} fit, as are
{helpb finegray_cif} point estimates and curves and both the analytic and the
bootstrap CIF interval. Two things are not, and the reasons differ:

{p2colset 9 30 32 2}{...}
{p2col:{cmd:finegray_predict, schoenfeld}}each residual is defined inside its
own interval, so every other interval's block is zero by construction and the
table is not a proportional-hazards diagnostic{p_end}
{p2col:{cmd:finegray_phtest}}this is the point rather than a gap: {opt tvc()}
is the modelled {it:answer} to a {cmd:finegray_phtest} rejection. Run the
diagnostic on the proportional fit, then fit this one, and use
{cmd:test [tvc1]x = [tvc2]x} here{p_end}
{p2colreset}{...}

{pstd}
{cmd:margins} is withdrawn after a {opt tvc()} fit ({cmd:e(marginsok)} is
empty) because there is no single linear predictor to average: which interval's
coefficients apply depends on the evaluation time, and {cmd:margins} has no way
to say which.

{pstd}
{bf:The analytic CIF interval under b({it:t}).} It was refused in development
builds, because the influence function behind it was derived for a single
exp({it:z}'b) multiplying every baseline increment, which a piecewise
b({it:t}) is not: each increment carries its own interval's linear predictor
and its own risk-set total, so both the prefix sums and the b-derivative term
change shape. It has since been re-derived. Interval {it:j}'s contribution is
the same construction run on that interval's events and design, so the
influence function is the sum over intervals of the pieces the proportional one
already computes, plus a derivative block for each interval's own
coefficients. It reuses the same accumulators, and at one interval it collapses
to the proportional formula term for term. The bootstrap arm is what the
analytic route is checked against.

{pstd}
{bf:Cost.} Each interval is one full pass of the scan, so a {it:J}-interval fit
costs roughly {it:J} times a proportional one plus the wider information
matrix; the sorting is done once. The two invariants that make the ordinary
scan linear-time -- exp({it:Z}'b) computed once, and a competing-event
subject's retained contribution added once and never revisited -- both fail
under b({it:t}), and rebuilding the accumulators at each boundary is what buys
them back inside each interval.


{marker lt}{...}
{title:Left truncation}

{pstd}
{bf:Under delayed entry finegray deliberately disagrees with stcrreg.} An
inverse-probability-of-censoring weight built from the censoring distribution
alone is {it:not} a valid weight for left-truncated data: with no censoring at
all it collapses to a constant, which cannot correct anything. Zhang, Zhang and
Fine (2011) show the resulting estimator is biased, and the bias does not
vanish as the sample grows. {cmd:stcrreg} uses that censoring-only weight; so
did {cmd:finegray} before version 1.3.0.

{pstd}
{bf:One weight stratum: the Geskus product-limit representation.} Writing
A(t) = G(t-)H(t-), where G is the delayed-entry-aware censoring survivor and H
is a reverse-time product-limit estimator of entry, a subject retained after a
competing event at X_i carries A(t-)/A(X_i-) instead of the censoring-only
ratio G(t-)/G(X_i-). Geskus (2011) states that this weight is equivalent to
Zhang-Zhang-Fine Weight 1, and Bellach et al. (2020) prove the equivalence for
continuous failure times. The package supplies and tests its own finite-sample
tie convention, which is why delayed-entry estimates move relative to
{cmd:stcrreg} and to earlier releases. {cmd:e(lt_weight)} reports
{cmd:zzf1_geskus} for this case.

{pstd}
{bf:Multiple weight strata: the equation-7 form.} The time-side stabilizer is
pooled, while each subject-side denominator is stratum-specific. When
{opt strata()} and {opt truncstrata()} specify the same grouping, this is Zhang,
Zhang and Fine's (2011, eq. 7) stratified nonparametric construction, reported
as {cmd:zzf1_stratified}.

{pstd}
{bf:The factorized extension, and what it assumes.} When {opt strata()} and
{opt truncstrata()} name {it:different} groupings, {cmd:finegray} estimates G
within {opt strata()}, estimates H within {opt truncstrata()}, and multiplies
the components in each observed combination. That cross-classification is a
package extension, not a construction attributed to Zhang et al., and
{cmd:e(lt_weight)} reports {cmd:zzf1_factorized} so that a consumer can tell
the extension apart from the ZZF construction it is not. The same contract is
used by estimation and by every post-estimation calculation.

{pstd}
The published same-group product-limit result does not require entry and
censoring to be independent. The factorized extension is a different
claim: because it estimates G without conditioning on {opt truncstrata()} and H
without conditioning on {opt strata()}, it requires factor-specific
separability. Within each observed censoring stratum, the censoring law must be
homogeneous across levels of {opt truncstrata()} that are not also in
{opt strata()}; within each entry stratum, the entry law must be homogeneous
across levels of {opt strata()} that are not also in {opt truncstrata()}. A
useful sufficient structure is that entry and censoring are independent
conditional on the joint cell, G depends only on {opt strata()}, and H depends
only on {opt truncstrata()}.

{pstd}
{bf:Which weights are valid for your data.} Pooled weights (no {opt strata()}
or {opt truncstrata()}) assume that the entry and censoring mechanisms do not
vary with model covariates in ways that require conditioning. When entry
depends on an observed discrete group, name it in {opt truncstrata()}; when
censoring does, name it in {opt strata()}. If one observed factor drives
{it:both} mechanisms -- a site or an enrolment wave, for example -- name it in
{bf:both} options, which puts the fit on the published stratified construction
rather than on the extension. Continuous covariate-dependent entry is
{bf:not supported}, and the command cannot infer or reject that dependence from
the realized data: do not use pooled weights in that setting unless a
scientifically defensible discrete stratification removes the dependence. If
that specification fails the positivity boundary, coarsen only when a coarser
mechanism model is scientifically defensible. Pooled or one-sided fits may be
useful sensitivity analyses, but their numerical feasibility does not make them
valid replacements.

{pstd}
{bf:Results with no delayed entry are unchanged, bit for bit.} When every
subject enters at the origin, H is identically 1, A collapses to G, and the
estimator is the existing right-censoring path. {cmd:e(lt_weight)} reports
{cmd:right_censoring} there, and {cmd:e(lt_vce)} reports
{cmd:not_applicable}.

{pstd}
{bf:Variance under delayed entry.} The default sandwich treats the estimated
weights as fixed: it does not propagate the uncertainty in estimating G and H,
and {cmd:e(lt_vce)} reports {cmd:fixed_weight_sandwich}. {opt nuisance} adds
the Zhang, Zhang and Fine (2011, Appendix B) terms for that uncertainty on the
pooled weight and reports {cmd:nuisance_adjusted}; see
{help finegray_methods##nuisance:The nuisance term} for the construction and
{help finegray_methods##refusals:What is refused, and why} for the stratified
cell. For {it:coefficient} standard errors that propagate weight-estimation
uncertainty by resampling, bootstrap the whole fit.

{pstd}
{bf:Why extreme weights are a warning and a zero is an error.} Unlike the
censoring-only weight, ZZF weights may legitimately exceed 1, so a maximum
weight above 1 under delayed entry is expected rather than alarming, and merely
extreme weights are reported as warnings while the fit proceeds. If A reaches
exactly zero at a consulted denominator or pooled stabilizer, the corresponding
risk contribution is undefined; {cmd:finegray} refuses the fit with
{cmd:r(459)} naming the offending groups instead of failing later as a
convergence error.


{marker weights}{...}
{title:Design weights}

{pstd}
{bf:Source.} Wogu, Zhao, Nichols and Cai (2021) derive the proportional
subdistribution hazards model for case-cohort data. Their estimating
equation, eq. (3) p.167, is the Fine and Gray score with a per-subject
availability weight rho_i multiplying each subject's contribution to every
risk-set sum S^(d)(beta, t) = n^-1 sum_i rho_i omega_i(t) Y_i(t) Z_i^(x)d
exp(beta'Z_i), while the IPCW factor omega_i is built from the censoring
Kaplan-Meier estimate of the {it:full cohort, unweighted} (sec. 3 p.167). The
Breslow baseline, eq. (4), carries the weight in S^(0) only. Because
dN_i is nonzero only for cause events, and every cause event has rho_i = 1
in their design, eq. (3) is identical to the general per-subject-weighted
score sum_i w_i integral (Z_i - Zbar_w) omega_i dN_i: one weight per
subject, in every risk-set sum and on every event term. {cmd:[pweight=]} uses this score form, but estimates
{it:G} from the
{it:analysis sample}, not from a separately available full cohort. It therefore
does not implement the full Wogu case-cohort estimator.

{pstd}
{bf:Scope of pweights.} Population interpretation requires the unweighted
analysis-sample Kaplan-Meier estimate to consistently estimate the censoring
survivor needed by the population score. Sampling must preserve the relevant
censoring distribution and independent censoring; weights on the score alone
do not establish this condition. Standard outcome-dependent case-cohort
sampling, retaining all cause events but only a fraction of other subjects,
generally changes the censoring risk sets. This implementation does not
correct that change and must not be used as a general case-cohort or
outcome-dependent sampling estimator. With no censoring this particular
restriction disappears. The supported computation is the weighted score with
unweighted sample {it:G}, as in {cmd:survival::finegray} followed by weighted
{cmd:coxph}; agreement with that implementation does not establish a
population interpretation for an arbitrary sampling design.

{pstd}
{bf:Computation.} A per-subject constant composes with the Kawaguchi et
al. (2021) forward-backward decomposition: every accumulator in the scan is
a sum of per-subject terms, so w_i scales each term once and the scan keeps
its O(np) shape. The log pseudo-likelihood is sum_i w_i [eta_i - log
S^(0)_w(T_i)] over cause events; the score is sum_i w_i (Z_i - Zbar_w(T_i)); the
information is sum_i w_i [S^(2)_w/S^(0)_w - Zbar_w Zbar_w']; the Breslow
increment at a cause event is w_i / S^(0)_w(T_i). The score residual s_i is
the per-unit-weight residual -- the weighted risk-set sums and the weighted
event counts enter the running sums, the subject's own outer w_i does not --
so one residual serves both weight types.

{pstd}
{bf:Variance.} Under {cmd:pweight}s the sandwich meat is sum_i (w_i s_i)(w_i
s_i)', summed within cluster under {opt cluster()}, and the finite-sample
factor is N/(N-1) on the number of subjects; that is the survey/IPW sandwich
{cmd:coxph(weights=, robust=TRUE)} forms on the {cmd:survival::finegray}
expansion. This is a {it:fixed-weight} sandwich: it does not propagate
uncertainty from estimating the censoring distribution. It must not be
interpreted as a full model-plus-sampling variance estimator with estimated
censoring weights. It is not
the variance Wogu et al. estimate: their Theorem 4.1 (p. 169) decomposes the
variance for a simple-random-sample subcohort as n^-1 sum_i rho_i (eta_i +
psi_i)^2 -- the weight entering {it:once}, a Horvitz-Thompson estimate of the
full-cohort model variance -- plus a (1-alpha)/alpha n^-1 sum_i rho_i mu_i^2
design term for the sampled non-cases. Agreement with the weighted Cox
implementation checks the fixed-weight convention; it does not establish
full design-based variance validity or account for the missing psi term. Under
{cmd:fweight}s the meat is sum_i
w_i s_i s_i' (w_i independent copies), the censoring Kaplan-Meier is
replicated too, and N is sum_i w_i: an {cmd:fweight}ed fit is the fit of
the expanded data. The model-based inverse information is refused under
{cmd:pweight}s: it is not a variance under informative sampling.

{pstd}
{bf:Post-estimation.} The influence function of the cumulative incidence
inherits the weighted Breslow increments dLambda_m = w_m / S^(0)_w(T_m) in
every sum over other events and is scaled once by the subject's own w_i,
with the same meat forms as above; the Schoenfeld residual is Z_i minus the
weighted risk-set mean. The weighted baseline is rebuilt from the data by
re-evaluating {cmd:e(wexp)}, whose variables are in the estimation-data
signature.

{pstd}
{bf:Identities the implementation is held to.} {cmd:[pw=1]} and
{cmd:[fw=1]} reproduce the unweighted fit bit for bit; an {cmd:fweight}ed fit
equals the {cmd:expand}ed fit to summation order; with no censoring, a
{cmd:pweight}ed fit equals the expanded data clustered on subject, which pins
the meat form; a constant pweight c leaves {cmd:e(b)} and {cmd:e(V)} unchanged
and gives ll_w = c (ll - N_fail log c). Externally the weighted fit is the same
estimator as {cmd:survival::finegray(weights=)} followed by a weighted
{cmd:coxph} -- coefficients, robust and cluster-robust standard errors, and the
weighted baseline. A finite-simulation recovery check also exercises one
outcome- and covariate-dependent sampling scenario; passing its tolerance
bands does not establish consistency under that design or other designs. The package's QA suite, which is
distributed with the source in the
{browse "https://github.com/tpcopeland/Stata-Tools":Stata-Tools repository} and
not with the installed package, exercises these identities.

{pstd}
{bf:What is refused, and why.} {opt nuisance}: Wogu et al. write the psi
term of their sec. 4 variance with a rho-weighted at-risk count that differs
from the unweighted G of their sec. 3 estimator, and the package does not
adjudicate that here. {opt strata()}/{opt truncstrata()}: no
cross-validation arm. For {opt strata()} that is conservatism rather than the
absence of an oracle -- a {cmd:strata()} term in {cmd:survival::finegray}'s
formula becomes {cmd:istrat} and the censoring Kaplan-Meier is fitted as
{cmd:survfit(Surv(...) ~ istrat)} (source read, {cmd:survival} 3.8-6), and the
same call takes weights, so the cell can be opened once the arm is written; Wogu
et al. p. 167 likewise allow a stratified {it:Ghat}. For
{opt truncstrata()} no source weights the delayed-entry {it:H} side at all,
{cmd:cmprsk::crr(cengroup=)} has no weights, and the right-censored
case-cohort method of Kim et al. (2020) does not supply that extension. The
{opt bstrata()} and {opt tvc()} options are mechanically linear in the same
per-subject terms, but each cell needs its own cross-validation arm before it
opens. Delayed entry: the ZZF branch is already this package's extension,
and no source derives a design-weighted version of it; and
{helpb finegray_phtest}, because the correlation summary has no weighted
form in the corpus. The {cmd:svy} prefix is out of scope; {cmd:pweight}s with {opt cluster()} on the primary
sampling unit produce weighted estimates and PSU-clustered fixed-weight
standard errors, subject to the censoring condition above and without
censoring-weight estimation uncertainty, survey
strata, finite-population corrections or design degrees of freedom.


{marker boundary}{...}
{title:Weight support boundaries}

{pstd}
Under delayed entry the weight A is evaluated {it:per observed joint weight}
{it:cell}, so every level of {opt strata()} participates in a weight cell even
when {opt truncstrata()} is not specified. At most {bf:100} joint strata are
supported, each holding at least {bf:20} estimation-sample subjects; beyond
that {cmd:finegray} stops with {cmd:r(459)} rather than pooling groups behind
your back.

{pstd}
{bf:Neither boundary is overridable}, and both apply to delayed-entry fits
only; a fit without delayed entry is unaffected by either, which is why a
delayed-entry model with many {opt strata()} levels can stop with {cmd:r(459)}
where the same model fits without delayed entry. Both are {it:package}
{it:conventions}, not values derived from the underlying theory. G is estimated
within {opt strata()} groups and H within {opt truncstrata()} groups, then the
components are evaluated together for each observed cross-classified cell. The
ceiling and the floor limit how finely that configured weight may be
cross-classified before cell support becomes too sparse. Choosing to refuse
rather than to pool or drop is deliberate; the two numbers themselves are
conservative round figures. If you hit the boundary, reduce the number of
censoring strata.

{pstd}
{bf:The size boundary does not guarantee a usable weight.} The 20-subject floor
is a {it:size} check only: it bounds how many subjects a stratum holds, not
whether A stays away from zero where the weight scan divides by it. A retained
competing-event subject carries A(t-)/A(X_i-), and if its own stratum's
A(X_i-) is zero that weight is undefined. That is checked separately before the
fit and refused with {cmd:r(459)}, naming the count and the offending
joint-group codes. Splitting into more entry strata makes it {it:more} likely,
because each stratum's entry distribution is then estimated from fewer
subjects.


{marker fv}{...}
{title:Factor variables and margins}

{pstd}
{bf:Why design columns are rebuilt by value.} The post-estimation commands
rebuild factor-variable design columns on demand from the expansion
recorded at estimation ({cmd:e(fvsemantic)}), keyed to each level's
{bf:value}. They do not re-run {cmd:fvrevar} against the data in memory,
so neither a changed {cmd:fvset} base nor a shifted level support can
silently re-pair a column with the wrong coefficient. Fitting on
{cmd:i.grp} over levels 1/2/3 and then shifting the data to levels 2/3/4
leaves three factor terms in both cases; matching them positionally would
apply the coefficient for level 2 to level 3, and so on, with no
error. Matching by value cannot.

{pstd}
A fitted level that is {bf:absent} from the current data is therefore not an
error: prediction succeeds for the rows that remain. What is refused is the
opposite case -- an observation at a level the fit never saw has no
coefficient, so {helpb finegray_predict} exits with {cmd:r(459)} naming the
variable and the fitted levels rather than collapsing that row onto the base
category.

{pstd}
{bf:Why the coefficient names and the design columns are kept separate.} The
coefficient table, {cmd:e(b)}, {cmd:e(V)}, {helpb finegray_phtest} rows and
{helpb finegray_cif}'s {cmd:r(profile_vars)} carry the factor-variable terms
you typed ({cmd:2.grp}), so {helpb lincom}, {helpb test}, {helpb testparm},
{helpb estimates table} and estout-style exporters all address coefficients in
your own vocabulary. Package-owned design columns such as {cmd:_fg_grp_2} are
recorded separately in {cmd:e(designvars)} for prediction and
post-estimation. {cmd:e(fvsemantic)} records the fit-time expansion whose
non-base terms pair 1:1 and in order with those design columns, so the {it:k}th
estimated coefficient and the {it:k}th post-estimation row always describe the
same term.

{pstd}
{bf:How {cmd:margins} addresses a factor term.} Estimation runs on the
generated {cmd:_fg_*} design columns, but what is posted is the full fit-time
expansion: {cmd:e(b)} and {cmd:e(V)} carry every base level ({cmd:1b.grp},
{cmd:0b.pelnode#co.ifp}) as a zero coefficient with a zero row and column,
exactly as {helpb stcox} and {helpb stcrreg} post theirs. That stripe is what
{cmd:margins}, {helpb contrast} and {helpb pwcompare} enumerate a factor's
levels from, so {cmd:margins grp}, {cmd:margins, dydx(grp)} and
{cmd:margins, at(grp=(1 2 3))} all run. Two mechanisms make it
work. First, the design-column list is stored as {cmd:e(designvars)}, not
{cmd:e(covariates)}: {cmd:margins} reads the latter name as the fit's
covariate list when it is present and resolves factors against it rather
than against the stripe, which is why {cmd:margins grp} used to stop with
{cmd:r(322)} "factor grp not found in list of covariates". Second,
{helpb finegray_predict}'s {cmd:xb} honours the {cmd:predict} contract
{cmd:margins} relies on: while it runs, {cmd:margins} reposts {cmd:e(b)}
renamed onto its own level-indicator variables, sets those to the
{opt at()} values and calls {cmd:predict}; a stripe that no longer names the
fitted terms is therefore scored by name, and the ordinary rebuild from the
raw variables is used otherwise. Inside the package nothing pairs with
{cmd:e(b)} by position any more: every consumer of the estimate -- the CIF,
the linear predictor, the Schoenfeld residuals, the bootstrap refits, the
baseline rebuild -- reads the non-base vector through one accessor
({cmd:_finegray_bnb} in Stata, {cmd:_finegray_beta()} in Mata) that drops the
base columns by their stripe marker, so a factor fit and a fit on hand-built
indicator columns give bit-identical post-estimation output. Margins are on
the linear-predictor
(log-SHR) scale; {cmd:e(marginsok)} lists {cmd:xb} only, because the CIF
depends on the baseline as well as on {cmd:e(b)} and a delta-method
derivative through {cmd:e(b)} alone would understate its variance. Use
{helpb finegray_cif} with {opt at()} for covariate-profile quantities on the
CIF scale, and {helpb finegray_cif##over:finegray_cif, over()} for the group
curves that a factor-level margin after this estimator is usually asking
for. {opt tvc()} fits are posted narrow, with no base-level columns, and
withdraw {cmd:margins} ({cmd:e(marginsok)} empty) because there is no
single linear predictor to average.


{marker mi}{...}
{title:Multiple imputation}

{pstd}
{cmd:finegray} runs under {helpb mi estimate:mi estimate, cmdok:}. The
estimator is an M-estimator whose coefficients are on the log-SHR scale with a
sandwich variance, so Rubin's rules apply to {cmd:e(b)} and {cmd:e(V)}
unchanged; nothing about the fit itself is different. {cmd:cmdok} is required
because {cmd:mi estimate}'s supported-command list is internal to Stata and
community-contributed commands cannot be added to it.

{pstd}
{bf:Why post-estimation is refused after a fit on {cmd:mi} data.} There are two
reasons and each is sufficient. The first is mechanical: those commands need
the fit's design columns and its entry-time column, and on {cmd:mi} data
{cmd:finegray} does not write them. The second is statistical: after pooling
there is no single baseline hazard to predict from, and pooling a cumulative
incidence curve across imputations is a different estimand from pooling a
coefficient.

{pstd}
{bf:Why the support columns are not written.} The persistent design
columns, entry-time column and dataset characteristics are post-estimation
support, not part of the fit -- the fit runs on temporary variables inside
{cmd:preserve} either way. In {cmd:mi} data they would be unregistered
variables: {cmd:mi describe} would report them, and under {cmd:mlong} or
{cmd:flong} they would carry values on some imputations and not
others. {cmd:finegray} therefore routes them through temporary variables
on {cmd:mi} data, which is why they do not survive the command, and why
post-estimation refuses rather than answering from columns that are gone.

{pstd}
{bf:Why a variable named {cmd:_mi_m} is not mi data.} Detection is on
{cmd:mi}'s own {it:dataset characteristics} -- {cmd:_dta[_mi_style]}, or
{cmd:_dta[_mi_substyle]}, which is what {cmd:mi estimate} leaves behind on
{cmd:flong} data. Those cover all four styles however the command was
reached. A variable merely {it:named} {cmd:_mi_m}, {cmd:_mi_id} or
{cmd:_mi_miss} in ordinary data is not mi data and is not treated as
such: those are legal names, and the dataset carries no {cmd:_mi_*}
characteristic. {cmd:mi extract} removes the characteristics, so a fit after
{cmd:mi extract} is an ordinary fit with ordinary post-estimation.


{marker cif}{...}
{title:Cumulative incidence}

{pstd}
The predicted cumulative incidence for a covariate profile is

{p 8 8 2}
CIF(t | z) = 1 - exp( -H0(t) * exp(z'b) ),

{pstd}
where H0(t) is the fitted baseline cumulative subdistribution hazard, a
right-continuous step function over the distinct cause-of-interest event
times. The baseline CIF is F0(t) = 1 - exp(-H0(t)), and the
covariate-adjusted CIF rescales the baseline {it:survival}: CIF(t|z) = 1 -
(1 - F0(t))^exp(z'b). Raising the CIF itself to the exp(z'b) power is a
common mistake and moves the CIF in the wrong direction (toward 0) when
z'b > 0.

{pstd}
{bf:Under a {opt tvc()} fit} the baseline is accumulated interval by
interval: the part of H0 falling inside interval {it:j} is multiplied by
that interval's exp(z'b_j), and the CIF is 1 - exp(-{it:sum}). There is
still one baseline.

{pstd}
{bf:Why the analytic interval is fixed-weight.} The confidence band is computed
from the per-subject influence functions of the CIF, propagating the
uncertainty in both the coefficient vector {cmd:e(b)} and the baseline
cumulative subdistribution hazard, and limits are formed on the complementary
log-log scale so they remain inside (0,1). The standard error treats the fitted
weight functions as known, so under heavy censoring or delayed entry it can
omit weight-estimation variability, and it is unchanged after a
{help finegray_methods##nuisance:nuisance} fit. {opt bootstrap()} re-estimates
the weight functions in each replication and is the route to an interval that
includes them.

{pstd}
{bf:Why the bootstrap needs at least 25 replications.} A bootstrap standard
error is the sample standard deviation of the replicate estimates, and below
about 25 replications that standard deviation is itself mostly noise. At least
25 must be requested and at least 25 must succeed. Nonconverged refits, and
refits whose resample loses a factor level so that the coefficient vector no
longer matches the stored covariate profile, are skipped and counted rather
than silently averaged in.

{pstd}
{bf:Why the default grid is thinned and the tail is drawn.} The estimation grid
ends at the last cause-event time, but the CIF is flat from there to the last
observed analysis time, and the graph draws that tail as {helpb sts graph} and
{helpb stcurve} do. The (0,0) origin and that terminal segment are display-only
and are not written to {cmd:r(table)} or {opt saving()}, because they are
properties of the picture rather than estimates. A requested time past the last
cause-event time repeats the terminal estimate and one before the first
cause-event time returns exactly 0 with no limits: both are the correct
step-function answers, which is why they are flagged with a note rather than
refused or silently returned.


{marker phtest}{...}
{title:Proportionality diagnostic}

{pstd}
{helpb finegray_phtest} reports, per covariate, the correlation {it:rho}
between that covariate's raw Fine-Gray Schoenfeld residual series and a chosen
function of event time. That correlation is the entire reported quantity: it is
a descriptive diagnostic, not a test. Time patterns in the residuals suggest
that a covariate's effect may change over time; treat a correlation far from
zero as a flag for follow-up.

{pstd}
{bf:Why no chi-squared and no p-value.} Earlier releases squared and rescaled
this correlation into {cmd:n*rho^2} and referred it to a one-degree-of-freedom
chi-squared, printing a {cmd:Prob>chi2}. That reference distribution was not
established for this statistic under the proportional {it:subdistribution}
hazards model, so no null calibration was claimed by anything. The chi-squared
and the p-value were removed rather than relabeled. Use the correlation, the
residual pattern, and sensitivity across {opt time()} choices as descriptive
evidence; use a published subdistribution-PH method for formal inference.

{pstd}
{bf:Why there is no omnibus test.} Versions before 1.2.0 printed a
{it:Global test} row holding the sum of the per-covariate 1-df statistics,
referred to a chi-squared with {it:p} degrees of freedom without estimating the
joint covariance among components. The printed probability therefore had no
established null distribution, and it too was removed rather than
relabeled. Li, Scheike and Zhang (2015) give cumulative-residual processes with
simulated null distributions and Zhou et al. (2013) give a score test; neither
method is implemented in this package, and for a formal omnibus test you need
software that implements one of them. To {it:model} rather than test a
departure from proportionality, {help finegray_methods##tvc:tvc()} fits a
piecewise-constant beta({it:t}) and {cmd:test [tvc1]}{it:x}
{cmd:= [tvc2]}{it:x} is the corresponding Wald test.

{pstd}
{bf:Why a constant time function is an error.} The diagnostic is only defined
where it can be computed. If every cause event occurs at a single time, the
time function is constant and no correlation exists, so
{cmd:finegray_phtest} exits with {cmd:r(459)} rather than reporting a blank
row. The same applies to any individual term whose raw residuals do not vary
across cause-event times.


{marker stcrreg}{...}
{title:Comparison with stcrreg}

{pstd}
Without delayed entry, {cmd:finegray} uses the ordinary Fine-Gray risk set and
variance conventions, and {helpb finegray_predict} maps its baseline CIF,
linear predictor, cumulative subhazard and Schoenfeld residuals to the
corresponding {helpb stcrreg} quantities. {opt xb} is numerically identical to
{cmd:stcrreg}'s {cmd:predict, xb}; the baseline CIF with all covariates set to
0 reproduces {cmd:predict, basecif}; and the fitted baseline cumulative
subhazard equals H0(t) = -ln(1 - {cmd:basecif}) at each distinct event
time. The per-observation {opt cif} is the covariate-adjusted CIF, which
{cmd:stcrreg} exposes only through {cmd:stcurve, cif at()} rather than
{cmd:predict}, and it matches to numerical precision.

{pstd}
{bf:Ties in the Schoenfeld residuals.} Residuals are identical to
{cmd:stcrreg}'s {bf:at untied cause-event times}. At a {bf:tied} cause-event
time the two implementations split the residual among the simultaneous events
using different conventions, so an individual residual at a tied time can
differ; the {bf:sum of the residuals within each event time is identical}, as
is the overall score (their grand total, which is zero at the estimate). Only
the per-observation values at tied times are affected -- untied times, the
per-time totals, and every quantity that aggregates over event times are
unchanged.

{pstd}
{bf:Under delayed entry, parity is neither expected nor a validity}
{bf:criterion.} {cmd:stcrreg} uses a censoring-only weight; see
{help finegray_methods##lt:Left truncation}. Delayed-entry coefficients,
standard errors, baseline hazards, predictions and CIFs all change relative to
{cmd:stcrreg} and relative to {cmd:finegray} before version 1.3.0.

{pstd}
{bf:Declaring the data differs too.} {cmd:finegray} is {cmd:stset} on "any
event" and told which value is the cause of interest, whereas {cmd:stcrreg} is
{cmd:stset} on the cause itself and told which values compete. A
{opt tvc()} comparison also differs in parameterization: {cmd:stcrreg}
parameterizes a threshold interaction, so its {cmd:main} coefficient applies on
(0, {it:c}] and {cmd:main}+{cmd:tvc} on {it:t} > {it:c}, where {cmd:finegray}
reports the two interval coefficients directly.


{marker performance}{...}
{title:Performance}

{pstd}
For a fixed covariate dimension and a bounded number of weight strata, each
forward-backward score scan is O(np) and the information scan is O(np^2); the
command does not expand the data over event times.

{pstd}
{bf:Why {cmd:e(basehaz)} is opt-in.} That matrix has roughly N/2 rows, and
building a Stata matrix that tall is O(rows^2) -- at N = 200,000 it took longer
than the model fit itself. It is not needed for post-estimation, because
{helpb finegray_cif} and {helpb finegray_predict} rebuild the same curve
internally, and {cmd:predict, basecshazard} returns the baseline as a variable
at O(N) cost. Ask for {opt basehaz} when you want the matrix itself, or when
you intend to {helpb estimates:estimates save} the fit and predict from it in a
later session.

{pstd}
{bf:Why the baseline is cached in Mata.} The baseline curve is kept in Mata
after every fit, where it costs nothing, so that post-estimation can use it
without ever building a Stata matrix -- which is also what lets
{cmd:predict, cif} work on new data after the estimation sample has been
dropped. {cmd:e(bh_key)} says which fit that cached curve belongs to. It must
be presented by post-estimation and is refused if it does not match, so a curve
from an earlier fit can never answer for the current one. The key is a per-fit
token carrying a salt that {cmd:mata clear} cannot reset, so no two fits can
present the same one.

{pstd}
{bf:Why the entry time is recorded twice.} On a multiple-record fit each
subject's earliest entry time is recorded both in the dataset characteristic
{cmd:_dta[_finegray_entryvar]} and in {cmd:e(entryvar)}, because the
characteristic travels with the data and {cmd:e()} travels with the
estimates. Reading {cmd:_t0} instead would silently substitute per-record entry
times for subject-level ones.


{marker citation}{...}
{title:Citation scope}

{pstd}
Fine and Gray (1999) ground the model, right-censoring risk sets, variance
structure, and Schoenfeld-type residual plots. Zhang et al. (2011) ground
left-truncated Weight 1 in its published b/S form; Geskus (2011) grounds the
G*H product-limit representation and tie ordering; Bellach et al. (2020) ground
their continuous-time equivalence. Bellach et al. (2019) ground the
estimated-weight variance term and the limitation for internal time-varying
covariates. Fine and Gray (1999) also ground {opt tvc()}: sec. 2 (pp. 497-498)
admits deterministic {it:Z}({it:t}) built from the baseline {it:Z} and {it:t},
and sec. 7 (p. 503) fits exactly such terms; the interval indicators
{opt tsplit()} builds are one instance, so the estimator is unchanged and only
the design grows. Zhou et al. (2011) ground {opt bstrata()}: the stratified
model, the within-stratum risk sets, the additive-over-strata estimating
equation, the two asymptotic regimes and the within-versus-pooled G that
distinguishes them, the regular-regime per-stratum Breslow baseline, and the
small-stratum variance caveat -- but not left truncation, which appears nowhere
in that paper, and not the highly-stratified closed-form variance, which this
package does not implement. Kawaguchi et al. (2021) ground only the
right-censoring, no-ties scan decomposition, not this package's tie,
left-truncation, or variance extensions.

{pstd}
For the proportionality diagnostic, Fine and Gray (1999) support
Schoenfeld-type residual plots for the subdistribution
model. {helpb finegray_phtest} reports the residual-time correlation as a
descriptive diagnostic only; it computes no marginal or omnibus test
statistic, so no null calibration is claimed. Zhou et al. (2013) and Li et
al. (2015) are cited to document formal testing methods for this model,
and neither is implemented in this package.


{marker references}{...}
{title:References}

{pstd}
Bellach A, Kosorok MR, Gilbert PB, Fine JP. General regression model for the
subdistribution of a competing risk under left-truncation and
right-censoring. {it:Biometrika} 2020; 107(4): 949-964.

{pstd}{browse "https://doi.org/10.1093/biomet/asaa034":doi:10.1093/biomet/asaa034}{p_end}

{pstd}
Bellach A, Kosorok MR, Rüschendorf L, Fine JP. Weighted NPMLE for the
subdistribution of a competing risk. {it:JASA} 2019; 114(525): 259-270.

{pstd}{browse "https://doi.org/10.1080/01621459.2017.1401540":doi:10.1080/01621459.2017.1401540}{p_end}

{pstd}
Fine JP, Gray RJ. A proportional hazards model for the subdistribution of a
competing risk. {it:JASA} 1999; 94(446): 496-509.

{pstd}{browse "https://doi.org/10.1080/01621459.1999.10474144":doi:10.1080/01621459.1999.10474144}{p_end}

{pstd}
Geskus RB. Cause-specific cumulative incidence estimation and the Fine and Gray
model under both left truncation and right censoring. {it:Biometrics}
2011; 67(1): 39-49.

{pstd}{browse "https://doi.org/10.1111/j.1541-0420.2010.01420.x":doi:10.1111/j.1541-0420.2010.01420.x}{p_end}

{pstd}
Kawaguchi ES, Shen JI, Suchard MA, Li G. Scalable algorithms for large competing
risks data. {it:Journal of Computational and Graphical Statistics}
2021; 30(3): 685-693.

{pstd}{browse "https://doi.org/10.1080/10618600.2020.1841650":doi:10.1080/10618600.2020.1841650}{p_end}

{pstd}
Li J, Scheike TH, Zhang MJ. Checking Fine and Gray subdistribution hazards model
with cumulative sums of residuals. {it:Lifetime Data Analysis} 2015; 21(2): 197-217
(online 2014).

{pstd}{browse "https://doi.org/10.1007/s10985-014-9313-9":doi:10.1007/s10985-014-9313-9}{p_end}

{pstd}
Wogu AF, Zhao S, Nichols HB, Cai J. Proportional subdistribution hazards
model for competing risks in case-cohort studies. {it:American Journal of Applied Mathematics}
2021; 9(5): 165-185.

{pstd}{browse "https://doi.org/10.11648/j.ajam.20210905.12":doi:10.11648/j.ajam.20210905.12}{p_end}

{pstd}
Zhang X, Zhang M-J, Fine J. A proportional hazards regression model for the
subdistribution with right-censored and left-truncated competing risks
data. {it:Statistics in Medicine} 2011; 30(16): 1933-1951.

{pstd}{browse "https://doi.org/10.1002/sim.4264":doi:10.1002/sim.4264}{p_end}

{pstd}
Zhou B, Fine J, Laird G. Goodness-of-fit test for proportional subdistribution
hazards model. {it:Statistics in Medicine} 2013; 32(22): 3804-3811.

{pstd}{browse "https://doi.org/10.1002/sim.5815":doi:10.1002/sim.5815}{p_end}

{pstd}
Zhou B, Fine J, Latouche A, Labopin M. Competing risks regression for clustered
data. {it:Biostatistics} 2012; 13(3): 371-383.

{pstd}{browse "https://doi.org/10.1093/biostatistics/kxr032":doi:10.1093/biostatistics/kxr032}{p_end}

{pstd}
Zhou B, Latouche A, Rocha V, Fine J. Competing risks regression for stratified
data. {it:Biometrics} 2011; 67(2): 661-670.

{pstd}{browse "https://doi.org/10.1111/j.1541-0420.2010.01493.x":doi:10.1111/j.1541-0420.2010.01493.x}{p_end}


{pstd}
Kim S, Xu Y, Zhang M-J, Ahn K-W. Stratified proportional subdistribution
hazards model with covariate-adjusted censoring weight for case-cohort
studies. {it:Scandinavian Journal of Statistics} 2020;47:1222-1242.
{p_end}
{pstd}{browse "https://doi.org/10.1111/sjos.12461":doi:10.1111/sjos.12461}.


{marker author}{...}
{title:Author}

{pstd}Timothy P Copeland, Karolinska Institutet{p_end}

{pstd}Report bugs and suggestions at{break}
{browse "https://github.com/tpcopeland/Stata-Tools":https://github.com/tpcopeland/Stata-Tools}{p_end}


{title:Also see}

{psee}
Online: {helpb finegray}, {helpb finegray_predict}, {helpb finegray_cif},
{helpb finegray_phtest}, {helpb stcrreg}, {helpb stcox}, {helpb stset}

{hline}
