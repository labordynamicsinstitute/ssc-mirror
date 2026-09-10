{smcl}
{* *! version 1.3.2  08sep2026}{...}
{vieweralsosee "finegray_methods" "help finegray_methods"}{...}
{vieweralsosee "finegray_predict" "help finegray_predict"}{...}
{vieweralsosee "finegray_cif" "help finegray_cif"}{...}
{vieweralsosee "finegray_phtest" "help finegray_phtest"}{...}
{vieweralsosee "[ST] stcrreg" "help stcrreg"}{...}
{vieweralsosee "[ST] stcox" "help stcox"}{...}
{viewerjumpto "Syntax" "finegray##syntax"}{...}
{viewerjumpto "Description" "finegray##description"}{...}
{viewerjumpto "Options" "finegray##options"}{...}
{viewerjumpto "Remarks" "finegray##remarks"}{...}
{viewerjumpto "Multiple imputation" "finegray##mi"}{...}
{viewerjumpto "Left truncation" "finegray##lt"}{...}
{viewerjumpto "Weights" "finegray##weights"}{...}
{viewerjumpto "Examples" "finegray##examples"}{...}
{viewerjumpto "Stored results" "finegray##results"}{...}
{viewerjumpto "Methods and formulas" "finegray##methods"}{...}
{viewerjumpto "Author" "finegray##author"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{cmd:finegray} {hline 2}}Fine-Gray competing risks regression{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:finegray}
{varlist}
{ifin}
[{it:{help finegray##weights:weight}}]{cmd:,}
{opt comp:ete(varname)}
{opt cau:se(#)}
[{it:options}]

{pstd}Replay the last results{p_end}

{p 8 17 2}
{cmd:finegray}
[{cmd:,}
{opt noshr}
{opt l:evel(#)}
{opt coefl:egend}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth comp:ete(varname)}}event type variable (0=censored, 1, 2, ...){p_end}
{synopt:{opt cau:se(#)}}value of {it:compete()} for cause of interest{p_end}

{syntab:Model}
{synopt:{opt cens:value(#)}}censoring value in {it:compete()}; default is {cmd:0}{p_end}
{synopt:{opth str:ata(varlist)}}stratify censoring distribution (numeric){p_end}
{synopt:{opth trunc:strata(varlist)}}stratify entry distribution (numeric){p_end}
{synopt:{opth bstr:ata(varname)}}stratify the baseline subhazard (numeric){p_end}
{synopt:{opth tvc(varlist)}}covariates with a time-varying effect{p_end}
{synopt:{opt tsplit(numlist)}}interior interval boundaries for {opt tvc()}{p_end}

{syntab:SE/Robust}
{synopt:{opth cl:uster(varname:numvar)}}adjust SEs for intragroup correlation{p_end}
{synopt:{opt noadj:ust}}omit finite-sample adjustment to the sandwich{p_end}
{synopt:{opt norob:ust}}report model-based SEs, not sandwich{p_end}
{synopt:{opt nuis:ance}}add the estimated-{it:G} term to the sandwich meat{p_end}

{syntab:Reporting}
{synopt:{opt noshr}}report coefficients, not hazard ratios{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:c(level)}{p_end}
{synopt:{opt nolog}}suppress iteration log{p_end}
{synopt:{opt baseh:az}}post the cumulative subhazard in {cmd:e(basehaz)}{p_end}

{syntab:Optimization}
{synopt:{opt iter:ate(#)}}maximum iterations; default is {cmd:200}{p_end}
{synopt:{opt tol:erance(#)}}convergence tolerance; default is {cmd:1e-8}{p_end}
{synoptline}
{p 4 6 2}
{it:varlist} may contain factor variables and interactions; see
{help fvvarlist}. Supports {cmd:i.}{it:varname},
{cmd:ib}{it:#}{cmd:.}{it:varname}, {cmd:ibn.}{it:varname} (interactions only),
{cmd:c.}{it:varname}, {cmd:#}, and {cmd:##} operators.
{p_end}
{p 4 6 2}
{cmd:pweight}s and {cmd:fweight}s are allowed for right-censored data; see
{help weight} and {help finegray##weights:Weights} below. The weight must be
constant within {cmd:id()}.
{p_end}
{p 4 6 2}
Data must be {cmd:stset}. Without {cmd:id()} each record is one subject, as
{cmd:stset} itself and {helpb stcrreg} treat it, and {cmd:e(idvar)} is
empty. With {cmd:id()} a subject may contribute multiple records when its
intervals are contiguous and the model covariates,
{opt strata()}, {opt truncstrata()}, {opt bstrata()}, {opt cluster()}, and
weight variables are constant
within {cmd:id()} (e.g. delayed-entry or {helpb stsplit} data); such records are
reduced automatically to one risk-set unit. Left-truncated data are
supported. Constancy is judged exactly -- any difference at all in a field
documented as constant within {cmd:id()} is refused with {cmd:r(198)} -- while
contiguity is judged relatively: two adjacent records are contiguous when
|{cmd:_t0} - previous {cmd:_t}| is at most 1e-12 times the larger of the two
boundaries in absolute value (exactly 0 when both are 0), so the same rule
applies whatever the time scale and boundaries built by two different
arithmetic routes are not refused over rounding.
{p_end}

{pstd}
{bf:Post-estimation:}

{p 8 17 2}
{helpb finegray_predict}
{dtype}
{newvar}
{ifin}{cmd:,}
[{opt xb} {opt cif} {opt sch:oenfeld} {opt time:var(varname)} {opt ci}
{opt basecsh:azard} {opt l:evel(#)} {opt boot:strap(#)} {opt seed(#)}
{opt att:ime(#)}]

{p 8 17 2}
{helpb finegray_cif}
[{cmd:,} {opt at(var=# ...)} {opth over(varname)} {opt att:ime(numlist)}
{opt ti:mepoints(numlist)} {opt bstrat:um(#)} {opt ci} {opt l:evel(#)}
{opt sav:ing(filename[, replace])} {opt boot:strap(#)} {opt seed(#)}
{opt nograph} {it:twoway_options}]

{p 8 17 2}
{helpb finegray_phtest}
[{cmd:,} {opt time(rank|log|identity)} {opt det:ail}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:finegray} fits the Fine and Gray (1999) subdistribution hazard model for
competing risks data.

{pstd}
It estimates subdistribution hazard ratios (SHR) which quantify the effect of
covariates on the cumulative incidence of a cause of interest in the presence of
competing events.

{pstd}
The estimator uses a native forward-backward scan adapted from Kawaguchi
et al. (2021) that avoids data expansion. Their published decomposition
covers right-censored data without ties; tie handling and delayed entry
are package extensions.

{pstd}
{bf:Methods, formulas, grounding and design rationale are in}
{helpb finegray_methods}. This file documents what to type and what each option
does.

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth compete(varname)} specifies the variable containing event types. Typically
coded as 0 = censored, 1 = cause 1, 2 = cause 2, etc. Must be consistent with
the {cmd:stset} failure indicator.

{pmore}
{cmd:compete()} must be observed on every record of the estimation sample. A
record whose event type is {it:missing} is refused with {cmd:r(198)}, not
dropped. The usual way to arrive at a missing {cmd:compete()} is through
{helpb stsplit}; carry the subject's event type onto every episode before
fitting, or {cmd:stset} a separate failure indicator. See
{help finegray_methods##refusals:What is refused, and why}.

{phang}
{opt cause(#)} specifies which value of {it:compete()} represents the cause of
interest.

{dlgtab:Model}

{phang}
{opt censvalue(#)} specifies the value in {it:compete()} that represents
censoring. Default is {cmd:0}.

{phang}
{opth strata(varlist)} stratifies the Kaplan-Meier censoring distribution
estimation by the specified variables. This is appropriate when the censoring
mechanism differs across groups (e.g., treatment arms or study sites).

{phang}
{opth truncstrata(varlist)} stratifies the {it:entry} (left-truncation)
distribution by the specified variables. It is the entry-side counterpart of
{opt strata()}, which remains the {it:censoring}-side option; the two are
specified independently and cross-classified into joint weight strata.

{pmore}
{opt truncstrata()} requires delayed entry ({cmd:r(198)} otherwise). Each variable must be
constant within subject, and missing values are excluded. Joint weight cells
are subject to a hard support boundary; see {help finegray_methods##boundary:Weight support boundaries}.

{phang}
{opth bstrata(varname)} fits the stratified proportional subdistribution
hazards model of Zhou, Latouche, Rocha and Fine (2011): one unconstrained
baseline per level of {it:varname}, one shared coefficient vector,

{pmore2}
lambda_1k(t | Z) = lambda_1k0(t) exp(Z'b),   k = 1, ..., K.

{pmore}
Use it to adjust for a discrete factor whose subdistribution hazards are
markedly non-proportional {it:without} estimating its effect.

{pmore}
{bf:Three different things are called "strata" here.} Only {opt bstrata()}
means what {cmd:stcox}'s {cmd:strata()} means.

{synoptset 18 tabbed}{...}
{synopt:{cmd:bstrata()}}the baseline subhazard -- what {cmd:stcox, strata()} means{p_end}
{synopt:{cmd:strata()}}the Kaplan-Meier censoring distribution G{p_end}
{synopt:{cmd:truncstrata()}}the entry (left-truncation) distribution H{p_end}

{pmore}
{it:varname} must be numeric and constant within {cmd:id()}; missing values
are excluded. It composes with {opt nuisance} and with {opt tvc()}. It is
{bf:not} allowed with delayed entry ({cmd:r(198)}). See
{help finegray_methods##bstrata:Baseline strata} for the scope, the variance,
and the two asymptotic regimes.

{phang}
{opth tvc(varlist)} names the covariates whose coefficient is allowed to differ
across intervals of analysis time, and {opt tsplit(numlist)} gives the interior
boundaries of those intervals,

{pmore2}
lambda_1(t | Z) = lambda_10(t) exp(Z'b(t)),   b(t) = b_j for t in interval j.

{pmore}
{opt tvc()} and {opt tsplit()} are required together ({cmd:r(198)}). {it:J} - 1
boundaries define {it:J} intervals, and each named covariate gets {it:J}
coefficients -- separate per interval, not main effect plus offsets.

{pmore}
{bf:Intervals are half-open at the left:} ({it:cut_j-1}, {it:cut_j}], so an
event at a boundary belongs to the earlier interval.

{pmore}
{bf:Reading the output.} The coefficient table gains equations: {cmd:main}
for proportional covariates and {cmd:tvc1} ... {cmd:tvc}{it:J} for the
intervals. Test constancy with {cmd:test [tvc1]x = [tvc2]x}.

{pmore}
{it:varlist} names {it:variables}, not design columns: {cmd:tvc(grp)} after {cmd:i.grp} frees all of
that factor's level effects together. Every interval must contain at least one
cause event ({cmd:r(459)}).

{pmore}
{bf:Time-varying effects are not time-varying covariates.} {opt tvc()} lets the
{it:coefficient} change with time, not the {it:covariate}; {cmd:finegray}
refuses records whose covariates vary within {cmd:id()}.

{pmore}
{opt tvc()} composes with {opt bstrata()} and {opt nuisance}; it is {bf:not}
allowed with delayed entry ({cmd:r(198)}). See
{help finegray_methods##tvc:Time-varying effects} for the grounding and the
post-estimation restrictions.

{dlgtab:SE/Robust}

{phang}
{opth cluster(varname)} adjusts standard errors for intragroup correlation, treating
whole clusters as the resampling unit. {cmd:finegray} requires more clusters
than coefficients and errors out otherwise. {opt cluster()} is not allowed with
{opt norobust}.

{phang}
{opt noadjust} suppresses the finite-sample adjustment applied to the
robust (sandwich) variance. By default {cmd:finegray} multiplies the
sandwich by {it:N}/({it:N}-1), or by {it:g}/({it:g}-1) when
{opt cluster()} is specified, matching {helpb stcrreg}. {opt noadjust} is
not allowed with {opt norobust}, which has no such adjustment.

{pmore}
The factor applies to the {bf:coefficient} variance {cmd:e(V)} only. The
analytic cumulative-incidence variance reported by {helpb finegray_cif} and by
{cmd:finegray_predict, cif ci} is the asymptotic influence-function sandwich
and carries no finite-sample factor, so {opt noadjust} changes {cmd:e(V)} and
the coefficient standard errors while leaving every cumulative-incidence
standard error exactly as it was. {cmd:e(vce_adjust)} reports which convention
is in force: {cmd:finite_sample} or {cmd:none}.

{phang}
{opt norobust} reports model-based standard errors from the observed
information matrix instead of the default sandwich. These are
{bf:not generally valid for Fine-Gray inference} and exist for inspection and
comparison; use the default sandwich to report results. {cmd:finegray} prints a
warning when {opt norobust} is used. See
{help finegray_methods##variance:Variance}.

{phang}
{opt nuisance} adds the Fine and Gray (1999, eq. 7-8) {it:psi} term to the
sandwich meat. The correction is {bf:not} always conservative and is {bf:not}
the default. Under delayed entry it adds the Zhang, Zhang and Fine (2011,
Appendix B) terms instead, available for the pooled weight only (refused with
{opt strata()} or {opt truncstrata()} under delayed entry, {cmd:r(198)}).

{pmore}
{opt nuisance} requires the sandwich ({cmd:r(198)} with {opt norobust}). It
composes with {opt bstrata()} and {opt tvc()}. It does {bf:not} propagate to
post-estimation: {helpb finegray_cif} and {helpb finegray_predict} use a
fixed-weight analytic CIF influence function. See
{help finegray_methods##nuisance:The nuisance term}.

{marker whichse}{...}
{phang}
{bf:Which standard error am I getting?} {cmd:e(vce_meat)} is the answer for
coefficients; {cmd:r(se_method)} for CIF intervals.

{pmore2}
{it:Coefficients} -- {cmd:e(b)}, {cmd:e(V)}:

{p2colset 13 46 48 2}{...}
{p2col:{bf:you type}}{bf:you get} ({cmd:e(vce_meat)}){p_end}
{p2col:(default)}fixed-weight sandwich ({cmd:fixed_weight}){p_end}
{p2col:{opt nuisance}}eta+psi, Fine and Gray eq. 7-8 ({cmd:nuisance_adjusted}){p_end}
{p2col:{opt norobust}}model-based inverse information ({cmd:not_applicable}){p_end}
{p2col:{opt cluster()}}cluster-robust ({cmd:fixed_weight}){p_end}
{p2col:{opt bstrata()}}per-stratum sandwich, summed ({cmd:fixed_weight}){p_end}
{p2col:{opt bstrata()} {opt nuisance}}Zhou et al. (2011) sec. 4.1 ({cmd:nuisance_adjusted}){p_end}
{p2col:{opt tvc()}}per-interval sandwich, summed ({cmd:fixed_weight}){p_end}
{p2col:{opt tvc()} {opt nuisance}}piecewise eta+psi ({cmd:nuisance_adjusted}){p_end}
{p2col:delayed entry}fixed-weight sandwich ({cmd:fixed_weight}){p_end}
{p2col:delayed entry {opt nuisance}}ZZF (2011) App. B ({cmd:nuisance_adjusted}){p_end}
{p2col:delayed entry {opt nuisance} {opt strata()}}{bf:refused}, {cmd:r(198)}{p_end}
{p2colreset}{...}

{pmore2}
{it:CIF intervals}: {opt ci} gives {cmd:analytic}; {opt ci bootstrap()} gives
{cmd:bootstrap}. Both are available on every fit, {opt tvc()} and
{opt bstrata()} included. The analytic route is fixed-weight in all cases.

{marker vcebootstrap}{...}
{phang}
{bf:Bootstrap coefficient inference.} The {opt bootstrap()} options of
{helpb finegray_cif} and {helpb finegray_predict} give CIF/prediction standard
errors, not coefficient ones. For coefficient-level inference that accounts for
estimating G(t), bootstrap the whole fit:

{pmore2}{cmd:. program define myfit, eclass}{p_end}
{pmore2}{cmd:.     quietly stset t, failure(ev) id(id)}{p_end}
{pmore2}{cmd:.     quietly finegray x1 x2, compete(ev) cause(1)}{p_end}
{pmore2}{cmd:. end}{p_end}
{pmore2}{cmd:. bootstrap _b, reps(500) seed(12345) cluster(id) idcluster(newid) group(id): myfit}{p_end}

{dlgtab:Reporting}

{phang}
{opt noshr} reports coefficients (log subdistribution hazard ratios) instead of
exponentiated coefficients (subdistribution hazard ratios).

{phang}
{opt level(#)} specifies the confidence level for confidence intervals. Default
is {cmd:c(level)}, which is initially 95; see {helpb set level}.

{phang}
{opt nolog} suppresses the iteration log.

{phang}
{cmd:finegray} typed with no {it:varlist} redisplays the last {cmd:finegray}
results. {opt noshr} and {opt level(#)} are honoured on replay.

{phang}
{opt coeflegend} redisplays the table with the {cmd:_b[]} name of each
coefficient in place of its statistics -- the way to read off the exact name of
a factor design column or a {opt tvc()} interval coefficient before typing it
into {helpb test} or {helpb lincom}. It is a replay-only option, and it may not
be combined with {opt level(#)} or {opt noshr} ({cmd:r(198)}): the legend table
reports neither an interval nor a coefficient scale.

{phang}
{opt basehaz} posts the baseline cumulative subdistribution hazard in
{cmd:e(basehaz)}, a matrix with one row per distinct cause-event time (under
{opt bstrata()}, one block per stratum). Not posted by default because building
a tall matrix is O(rows^2); for the baseline as a variable at O(N) cost, use
{cmd:predict, basecshazard}. Use {opt basehaz} when you want the matrix itself,
or when you will {helpb estimates:estimates save} the fit for a later session --
the cached baseline does not cross sessions.

{dlgtab:Optimization}

{phang}
{opt iterate(#)} specifies the maximum number of Newton-Raphson iterations; default
is {cmd:200}. If the model has not converged within {it:#} iterations, {cmd:finegray} reports
the last iterate with {cmd:e(converged)} set to 0. Post-estimation commands refuse
to run on a nonconverged fit with {cmd:r(430)}.

{phang}
{opt tolerance(#)} specifies the convergence tolerance. Default is
{cmd:tolerance(1e-8)}. Convergence is declared when the Newton decrement falls
below {it:#}; see {help finegray_methods##estimator:The estimator}.

{phang}
{cmd:finegray} requires the model to be identified. A covariate that
contributes no information to the cause-event risk sets, or a constant or
collinear column, is refused with {cmd:r(459)} naming the offending terms.


{marker remarks}{...}
{title:Remarks}

{pstd}
The Fine-Gray model directly models the subdistribution hazard. Subjects who
experience a competing event remain in the risk set with time-dependent weights
derived from the censoring distribution. A subdistribution hazard ratio (SHR)
greater than 1 indicates the covariate increases the cumulative incidence of the
cause of interest. The derivations and design rationale are in
{helpb finegray_methods}.

{pstd}
{bf:Factor variables and interactions:} {cmd:finegray} supports the full Stata
factor-variable syntax. Design columns are created with the prefix {cmd:_fg_}
and persist for {helpb finegray_predict}. Re-running {cmd:finegray} drops only
the columns its own prior run created and still owns: each is stamped with a
per-run marker, so a column you dropped and rebuilt yourself under the same
name is preserved and the fit is {cmd:r(198)} instead. Coefficient names follow the user's
specification ({cmd:2.grp}), so {helpb test}, {helpb lincom} and
{helpb estimates table} address them directly; each factor's base level is
posted with a zero coefficient for {helpb margins}. {cmd:ibn.} as a main effect
is {cmd:r(459)}; inside an interaction it is estimable. See
{help finegray_methods##fv:Factor variables and margins}.

{marker sideeffects}{...}
{pstd}
{bf:What {cmd:finegray} changes in your dataset.} The fit runs inside
{cmd:preserve} and is {cmd:sortpreserve}, so
{bf:no observation is dropped, altered, or reordered}. What persists:

{phang2}
{bf:1. Factor-variable design columns} {cmd:_fg_}{it:term}, one per expanded
term. A pre-existing {cmd:_fg_}{it:term} not created by this package's previous
run is never deleted: it is preserved and the fit is {cmd:r(198)}.

{phang2}
{bf:2. An entry-time column} {cmd:_fg_entry}, created only when multiple records
per subject are reduced. Required by post-estimation. Held to the same
ownership rule: a {cmd:_fg_entry} finegray did not create is preserved and the
fit is {cmd:r(198)}.

{phang2}
{bf:3. Dataset characteristics} recording the fit for post-estimation use.

{phang2}
{bf:4. A reduced {cmd:e(sample)}} on multiple-record data: one record per
subject, with {cmd:e(N)} counting subjects.

{pstd}
Because that reduction keeps one record per subject, a subject whose failure
record is not its last record (a second failure after the first, or follow-up
continued past the failure, both of which {cmd:stset ..., exit(time .)}
permits) is refused with {cmd:r(198)} rather than silently reduced to its
last record, because {cmd:finegray} models the subdistribution of a single
first event per subject. Keep each subject's first event (re-{cmd:stset}
without {opt exit(time .)}) or recode the outcome.

{pstd}
Items 1-3 are {bf:not} written on {cmd:mi} data; see {help finegray##mi:Multiple imputation}. Dropping {cmd:_fg_*}
design columns is supported (post-estimation rebuilds them); altering one in
place is {cmd:r(459)}. Do not drop {cmd:_fg_entry} while post-estimation on a
multiple-record fit is needed. For {helpb estimates:estimates save} workflows, request {opt basehaz}
at fit time so the baseline survives across sessions; {cmd:e(sample)} does not
survive and must be re-declared with {cmd:estimates esample:} after {cmd:estimates use}.

{marker mi}{...}
{pstd}
{bf:Multiple imputation.} {cmd:finegray} runs under
{helpb mi estimate:mi estimate, cmdok:}. All four {cmd:mi} styles work.

{phang2}{cmd:. webuse hypoxia, clear}{p_end}
{phang2}{cmd:. gen byte status = failtype}{p_end}
{phang2}{cmd:. replace ifp = . in 1/12}{p_end}
{phang2}{cmd:. mi set wide}{p_end}
{phang2}{cmd:. mi register imputed ifp}{p_end}
{phang2}{cmd:. mi register regular tumsize pelnode status dftime dfcens stnum}{p_end}
{phang2}{cmd:. mi impute regress ifp = tumsize pelnode, add(10) rseed(20260825)}{p_end}
{phang2}{cmd:. mi stset dftime, failure(dfcens==1) id(stnum)}{p_end}
{phang2}{cmd:. mi estimate, cmdok eform("SHR"): finegray ifp, compete(status) cause(1)}{p_end}

{pstd}
{bf:Post-estimation is not available after a fit on mi data} ({cmd:r(301)}). Refit on a
single dataset ({cmd:mi extract 0, clear}) to use post-estimation. Mi data is
detected by {cmd:_dta[_mi_style]} or {cmd:_dta[_mi_substyle]}, not by variable names. See
{help finegray_methods##mi:Multiple imputation}.

{marker bstrata}{...}
{pstd}
{bf:Baseline strata.} Right censoring only. What changes downstream:

{phang2}
The header gains the {opt bstrata()} variable and {cmd:e(k_bstrata)}. {cmd:e(basehaz)} becomes
{it:K}-by-3 ({it:bstratum}, {it:time}, {it:cumhazard}). {helpb finegray_predict} answers each row from its
own stratum's baseline. {helpb finegray_cif} requires {opt bstratum(#)} when there is more than one
stratum ({cmd:e(k_bstrata)} > 1) and refuses it otherwise; use {opt over()} on
the {opt bstrata()} variable for all strata at once.

{pstd}
A stratum with no cause event is noted and recorded in
{cmd:e(bstrata_noevent)}, and in {cmd:e(bstrata_noevent_x)} as
hexadecimal doubles ({cmd:%21x}) that Stata's numeric parser reads back
exactly -- the readable form rounds a noninteger stratum value, so compare
against the {cmd:%21x} form. Its CIF is refused. With one level,
{opt bstrata()} is the unstratified estimator, bit for bit. See
{help finegray_methods##bstrata:Baseline strata}.


{marker tvc}{...}
{pstd}
{bf:Time-varying effects.} Post-estimation after a {opt tvc()} fit:

{p2colset 9 30 32 2}{...}
{p2col:{cmd:finegray_predict, xb}}available; a function of time. {opt attime(#)} evaluates at one time{p_end}
{p2col:{cmd:finegray_predict, cif}}available; accumulates the baseline interval by interval{p_end}
{p2col:{cmd:finegray_predict, basecshazard}}available and unchanged{p_end}
{p2col:{cmd:finegray_cif}}available, including analytic {opt ci}{p_end}
{p2col:{cmd:ci bootstrap(#)}}available; each replication refits the whole model{p_end}
{p2col:{cmd:finegray_predict, schoenfeld}}{bf:not available}, {cmd:r(198)}{p_end}
{p2col:{cmd:finegray_phtest}}{bf:not available}, {cmd:r(198)}; use {cmd:test [tvc1]x = [tvc2]x}{p_end}
{p2col:{cmd:margins}}{bf:not available}, {cmd:r(498)}{p_end}
{p2colreset}{...}

{pstd}
See {help finegray_methods##tvc:Time-varying effects}.


{marker lt}{...}
{pstd}
{bf:Left truncation (delayed entry).} {cmd:finegray} supports left-truncated
data via {cmd:stset}'s {cmd:enter()} option.

{pstd}
{bf:Under delayed entry finegray deliberately disagrees with stcrreg.} It uses
the Zhang-Zhang-Fine Weight-1 contract. Delayed-entry coefficients, standard
errors, baselines and CIFs all change relative to {cmd:stcrreg} and to versions
before 1.3.1. Results with no delayed entry are unchanged, bit for bit. See
{help finegray_methods##lt:Left truncation}.

{pstd}
{cmd:e(lt_weight)} reports the weight computed: {cmd:right_censoring},
{cmd:zzf1_geskus}, {cmd:zzf1_stratified} or {cmd:zzf1_factorized}. Name the
covariate that drives entry in {opt truncstrata()}, and the one that drives
censoring in {opt strata()}.

{pstd}
{bf:Support boundary.} Under delayed entry, at most {bf:100} joint weight strata are
supported, each with at least {bf:20} subjects
({cmd:r(459)}). {bf:Neither boundary is overridable}, and both apply to delayed-entry
fits only; see {help finegray_methods##boundary:Weight support boundaries}.

{pstd}
{bf:Standard errors.} Use the default sandwich. {opt nuisance} adds the ZZF
Appendix B terms for the pooled weight. For coefficient-level bootstrap, see
{help finegray##vcebootstrap:Bootstrap coefficient inference}.

{pstd}
{bf:Proportional hazards diagnostic:} {helpb finegray_phtest} provides an
exploratory diagnostic using raw Schoenfeld residuals.

{pstd}
{bf:Cumulative incidence curves:} {helpb finegray_cif} plots the predicted CIF
with an optional confidence band and reports the CIF at fixed horizons. For
per-subject CIF limits, use {cmd:finegray_predict, cif ci}.

{pstd}
{bf:Margins:} {cmd:margins} is supported for the linear predictor in every model without
{opt tvc()}: {cmd:margins grp}, {cmd:margins, dydx(grp)}, etc. After {opt tvc()}, {cmd:margins} stops with
{cmd:r(498)}. Margins are on the log-SHR scale; for CIF-scale quantities use
{helpb finegray_cif} with {opt at()} and {opt over()}. See {help finegray_methods##fv:Factor variables and margins}.

{pstd}
{bf:Compatibility:} Without delayed entry, predictions map to the
corresponding {helpb stcrreg} quantities. See
{help finegray_methods##stcrreg:Comparison with stcrreg}.

{pstd}
{bf:Performance:} Each score scan is O(np); no data expansion. See
{help finegray_methods##performance:Performance}.

{pstd}
{bf:Limitations:} {cmd:by:} is not supported (use {cmd:if} conditions). {cmd:aweight}s, {cmd:iweight}s and
the {cmd:svy} prefix are not supported; use {cmd:pweight}s with {opt cluster()} on the primary
sampling unit.


{marker weights}{...}
{title:Weights}

{pstd}
{cmd:finegray} accepts {cmd:[pweight=}{it:exp}{cmd:]} and
{cmd:[fweight=}{it:exp}{cmd:]} on right-censored data. The weight must be
constant within {cmd:id()} ({cmd:r(198)} otherwise); zero or missing weights
leave the estimation sample; negative is {cmd:r(402)}; noninteger {cmd:fweight}
is {cmd:r(401)}.

{pstd}
{bf:pweight.} Every subject's contribution to every risk-set sum, score,
information and Breslow baseline is multiplied by its weight. The censoring
survivor {it:G} stays {bf:unweighted} and is estimated from the analysis
sample. Population interpretation requires sampling to preserve the required
censoring distribution and independent censoring. This is not a general
case-cohort or outcome-dependent sampling estimator; weighting the score does
not repair a distorted censoring estimate. See
{help finegray_methods##weights:Design weights}. The variance is the fixed-weight sandwich with meat
sum_i (w_i s_i)^2, cluster-summed under {opt cluster()}; {opt norobust} is
refused ({cmd:r(198)}). It omits uncertainty from estimating {it:G}.

{pstd}
{bf:fweight.} Replication semantics: a subject carrying {it:w} is {it:w}
identical subjects in risk sets, the censoring Kaplan-Meier, {cmd:e(N)} and
event counts.

{pstd}
{bf:What weights do not compose with}, each {cmd:r(198)}: {opt nuisance},
{opt strata()}/{opt truncstrata()}, {opt bstrata()}, {opt tvc()}, delayed
entry, and {helpb finegray_phtest}. Under {cmd:fweight}s the {opt bootstrap()}
option of {helpb finegray_cif} and {helpb finegray_predict} is also
{cmd:r(198)}: {helpb bsample} resamples rows, not the replicated subjects the
frequency weights stand for. The analytic {opt ci} is exact there -- an
fweighted fit is the fit of the replicated data -- so use it, or {helpb expand}
the data and bootstrap the expanded fit. See
{help finegray_methods##weights:Design weights}.

{pstd}
{bf:A weight declared in {cmd:stset} is not inherited.} Fitting on weighted
{cmd:stset} data with no command-line weight is {cmd:r(198)}. The weight
expression must name variables ({cmd:_n}/{cmd:_N} are refused); post-estimation
reconciles the rebuilt column against {cmd:e(sum_w)} and against
{cmd:e(wsig)}, a value-sensitive digest of the fit's own weights keyed by the
{cmd:stset} {opt id()} variable ({cmd:e(idvar)}) when one was declared and by
value alone otherwise, so a change that leaves the
total untouched -- including an exchange of two subjects' weights -- is
refused too. Estimates saved before this build carry no {cmd:e(wsig)} and
reconcile by total only; post-estimation prints a warning on every such call,
because a change that leaves {cmd:e(sum_w)} unmoved is then undetected and the
result may be computed from a weight column the fit never saw.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Setup}

{phang2}{cmd:. webuse hypoxia, clear}{p_end}
{phang2}{cmd:. gen byte status = failtype}{p_end}
{phang2}{cmd:. stset dftime, failure(dfcens==1) id(stnum)}{p_end}

{pstd}
{bf:Basic model}

{phang2}{cmd:. finegray ifp tumsize pelnode, compete(status) cause(1)}{p_end}

{pstd}
{bf:Stratified censoring distribution}

{phang2}{cmd:. finegray ifp tumsize, compete(status) cause(1) strata(pelnode)}{p_end}

{pstd}
{bf:Stratified baseline subhazard} (one baseline per group, shared coefficients)

{phang2}{cmd:. finegray ifp tumsize, compete(status) cause(1) bstrata(pelnode)}{p_end}
{phang2}{cmd:. finegray_cif, attime(1 5) bstratum(0) ci}{p_end}
{phang2}{cmd:. finegray_cif, attime(1 5) bstratum(1) ci}{p_end}

{pstd}
{bf:Baseline and censoring distribution both stratified} (Zhou et al. 2011,
regularly stratified regime)

{phang2}{cmd:. finegray ifp tumsize, compete(status) cause(1) bstrata(pelnode) strata(pelnode)}{p_end}

{pstd}
{bf:Piecewise-constant time-varying effect} (one coefficient per interval)

{phang2}{cmd:. finegray ifp tumsize pelnode, compete(status) cause(1) tvc(pelnode) tsplit(1)}{p_end}

{pstd}
Test whether that effect is in fact constant across the two intervals

{phang2}{cmd:. test [tvc1]pelnode = [tvc2]pelnode}{p_end}

{pstd}
Three intervals, the linear predictor at a chosen time, and the CIF

{phang2}{cmd:. finegray ifp tumsize pelnode, compete(status) cause(1) tvc(pelnode) tsplit(0.5 1.5)}{p_end}
{phang2}{cmd:. finegray_predict xb2, xb attime(2)}{p_end}
{phang2}{cmd:. finegray_cif, at(ifp=20 tumsize=5 pelnode=0) attime(1 3 5)}{p_end}

{pstd}
{bf:Sampling weights} (the design-weighted score; the censoring distribution
stays unweighted, and the sandwich is the pweight one)

{phang2}{cmd:. gen double sw = cond(pelnode == 1, 2, 1)}{p_end}
{phang2}{cmd:. finegray ifp tumsize [pweight = sw], compete(status) cause(1)}{p_end}
{phang2}{cmd:. finegray_cif, attime(1 5) ci}{p_end}

{pstd}
{bf:Model-based standard errors (default is robust/sandwich)}

{phang2}{cmd:. finegray ifp tumsize pelnode, compete(status) cause(1) norobust}{p_end}

{pstd}
{bf:Log-SHR (no exponentiation)}

{phang2}{cmd:. finegray ifp tumsize pelnode, compete(status) cause(1) noshr}{p_end}

{pstd}
{bf:CIF prediction}

{phang2}{cmd:. finegray ifp tumsize pelnode, compete(status) cause(1)}{p_end}
{phang2}{cmd:. finegray_predict cif_hat, cif}{p_end}

{pstd}
{bf:Cumulative-incidence curve and fixed-horizon table}

{phang2}{cmd:. finegray_cif, ci}{p_end}
{phang2}{cmd:. finegray_cif, attime(1 5 8) ci}{p_end}

{pstd}
{bf:Factor variables (automatic indicator expansion)}

{phang2}{cmd:. finegray i.pelnode ifp, compete(status) cause(1)}{p_end}

{pstd}
{bf:Factor variables with specified base category}

{phang2}{cmd:. finegray ib1.pelnode ifp, compete(status) cause(1)}{p_end}

{pstd}
{bf:Interaction: factor x continuous (full factorial)}

{phang2}{cmd:. finegray i.pelnode##c.ifp tumsize, compete(status) cause(1)}{p_end}

{pstd}
{bf:Margins (adjusted predictions)}

{phang2}{cmd:. finegray ifp tumsize pelnode, compete(status) cause(1)}{p_end}
{phang2}{cmd:. margins, at(ifp=(0 5 10)) predict(xb)}{p_end}
{phang2}{cmd:. margins, dydx(ifp) predict(xb)}{p_end}

{phang2}{cmd:. finegray i.pelnode##c.ifp tumsize, compete(status) cause(1)}{p_end}
{phang2}{cmd:. margins pelnode}{p_end}
{phang2}{cmd:. margins, dydx(pelnode) at(ifp=(5 15))}{p_end}
{phang2}{cmd:. contrast pelnode}{p_end}

{pstd}
{bf:Delayed entry with entry strata.} Name in {opt truncstrata()} the
covariates entry depends on, and in {opt strata()} those censoring
depends on; read {cmd:e(lt_weight)} and the weight diagnostics before
interpreting. Entry below depends on {cmd:z1} and censoring does not, so
the specification these data call for is {cmd:truncstrata(z1)} with no
{opt strata()}. The block is self-contained and runs as printed.

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 20260713}{p_end}
{phang2}{cmd:. set obs 24000}{p_end}
{phang2}{cmd:. gen byte z1 = runiform() < 0.5}{p_end}
{phang2}{cmd:. gen double z2 = rnormal()}{p_end}
{phang2}{cmd:. gen double ez = exp(0.5*z1 - 0.5*z2)}{p_end}
{phang2}{cmd:. gen double p1 = 1 - (1 - 0.5)^ez}{p_end}
{phang2}{cmd:. gen byte cause = cond(runiform() < p1, 1, 2)}{p_end}
{phang2}{cmd:. gen double v = runiform()}{p_end}
{phang2}{cmd:. gen double event_time = -ln(1 - (1 - (1 - v*p1)^(1/ez))/0.5) if cause == 1}{p_end}
{phang2}{cmd:. replace event_time = rexponential(1/(0.5*exp(0.5*z1 + 0.5*z2))) if cause == 2}{p_end}
{phang2}{cmd:. gen double censor_time = min(rexponential(1/0.15), 6)}{p_end}
{phang2}{cmd:. gen double entry_time = rexponential(1/cond(z1 == 1, 1.6, 0.5))}{p_end}
{phang2}{cmd:. gen double time = min(event_time, censor_time)}{p_end}
{phang2}{cmd:. gen byte status = cond(event_time <= censor_time, cause, 0)}{p_end}
{phang2}{cmd:. drop if !(entry_time < time)}{p_end}
{phang2}{cmd:. keep in 1/4000}{p_end}
{phang2}{cmd:. gen long id = _n}{p_end}
{phang2}{cmd:. gen byte any_event = status > 0}{p_end}
{phang2}{cmd:. stset time, failure(any_event == 1) id(id) enter(time entry_time)}{p_end}
{phang2}{cmd:. finegray z1 z2, compete(status) cause(1) truncstrata(z1)}{p_end}
{phang2}{cmd:. display "`e(lt_weight)'"}{p_end}
{phang2}{cmd:. display e(min_weight_prob), e(max_lt_weight)}{p_end}

{pstd}
{bf:Grouped cumulative incidence} on {cmd:webuse hiv_si}

{phang2}{cmd:. webuse hiv_si, clear}{p_end}
{phang2}{cmd:. gen byte any_event = status > 0}{p_end}
{phang2}{cmd:. stset time, failure(any_event==1) id(patnr)}{p_end}
{phang2}{cmd:. finegray ccr5, compete(status) cause(2)}{p_end}
{phang2}{cmd:. finegray_cif, over(ccr5) attime(2 5 10) ci}{p_end}
{phang2}{cmd:. finegray_cif, over(ccr5) ci}{p_end}

{pstd}
{bf:Multiple imputation}

{phang2}{cmd:. webuse hypoxia, clear}{p_end}
{phang2}{cmd:. gen byte status = failtype}{p_end}
{phang2}{cmd:. replace ifp = . in 1/12}{p_end}
{phang2}{cmd:. mi set wide}{p_end}
{phang2}{cmd:. mi register imputed ifp}{p_end}
{phang2}{cmd:. mi register regular tumsize pelnode status dftime dfcens stnum}{p_end}
{phang2}{cmd:. mi impute regress ifp = tumsize pelnode, add(10) rseed(20260825)}{p_end}
{phang2}{cmd:. mi stset dftime, failure(dfcens==1) id(stnum)}{p_end}
{phang2}{cmd:. mi estimate, cmdok eform("SHR"): finegray ifp tumsize, compete(status) cause(1)}{p_end}

{pstd}
{bf:An internal time-varying covariate is refused.} On {cmd:webuse pneumonia}
({bf:[ST] stcrreg} example 5) the exposure switches mid-stay, so it varies
within {cmd:id()} and the fit stops with {cmd:r(198)}. Its value at admission is
subject-constant and is accepted -- a baseline-exposure model, a different
estimand from the time-updated coefficient {helpb stcrreg} reports.

{phang2}{cmd:. webuse pneumonia, clear}{p_end}
{phang2}{cmd:. gen byte outcome = cond(died==1, 1, cond(discharged==1, 2, 0))}{p_end}
{phang2}{cmd:. gen byte any_event = outcome > 0}{p_end}
{phang2}{cmd:. stset ndays, failure(any_event==1) id(id)}{p_end}
{phang2}{cmd:. bysort id (ndays): gen byte pneu0 = pneumonia[1]}{p_end}
{phang2}{cmd:. finegray age pneu0, compete(outcome) cause(1)}{p_end}
{phang2}{cmd:. finegray age pneumonia, compete(outcome) cause(1)}{p_end}

{pstd}
{bf:Bootstrap inference for the coefficients.} The block above left
{cmd:pneumonia} in memory, so this one reloads {cmd:hypoxia} first; the
{cmd:stcrreg} comparison below then runs on the same data.

{phang2}{cmd:. webuse hypoxia, clear}{p_end}
{phang2}{cmd:. gen byte status = failtype}{p_end}
{phang2}{cmd:. stset dftime, failure(dfcens==1) id(stnum)}{p_end}
{phang2}{cmd:. program define fgboot, eclass}{p_end}
{phang2}{cmd:.     version 16.0}{p_end}
{phang2}{cmd:.     capture drop _st _d _t _t0}{p_end}
{phang2}{cmd:.     quietly stset dftime, failure(dfcens==1) id(newid)}{p_end}
{phang2}{cmd:.     finegray ifp tumsize pelnode, compete(status) cause(1) noshr nolog}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. bootstrap _b, reps(200) seed(13579) cluster(stnum) idcluster(newid): fgboot}{p_end}

{pstd}
{bf:Compare with stcrreg}

{phang2}{cmd:. stset dftime, failure(status==1) id(stnum)}{p_end}
{phang2}{cmd:. stcrreg ifp tumsize pelnode, compete(status == 2)}{p_end}

{pstd}
Two-interval time-varying effect comparison

{phang2}{cmd:. stcrreg ifp tumsize pelnode, compete(status == 2) tvc(pelnode) texp(_t > 1) noshr}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:finegray} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of subjects (replicated under {cmd:fweight}s){p_end}
{synopt:{cmd:e(sum_w)}}sum of weights (only with weights){p_end}
{synopt:{cmd:e(wsig_n)}}rows behind {cmd:e(wsig)} (only with weights){p_end}
{synopt:{cmd:e(N_fail)}}subjects with a cause-of-interest event{p_end}
{synopt:{cmd:e(N_compete)}}subjects with a competing event{p_end}
{synopt:{cmd:e(N_cens)}}censored subjects{p_end}
{synopt:{cmd:e(ll)}}log pseudo-likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log pseudo-likelihood at b=0 (the null model){p_end}
{synopt:{cmd:e(chi2)}}Wald chi-squared{p_end}
{synopt:{cmd:e(p)}}p-value for model chi-squared{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom (numerical rank of {cmd:e(V)}){p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters (only with {opt cluster()}){p_end}
{synopt:{cmd:e(converged)}}1 if converged, 0 otherwise{p_end}
{synopt:{cmd:e(N_delayed)}}subjects entering after time 0 (delayed entry){p_end}
{synopt:{cmd:e(N_G_trunc)}}observations with censoring {it:G(t)} floored at 1e-10{p_end}
{synopt:{cmd:e(k_bstrata)}}baseline strata fitted; {cmd:1} without {opt bstrata()}{p_end}
{synopt:{cmd:e(n_intervals)}}time intervals fitted; {cmd:1} without {opt tvc()}{p_end}
{synopt:{cmd:e(k_tvc)}}design columns with an interval-specific slope{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(cause)}}cause of interest value{p_end}
{synopt:{cmd:e(censvalue)}}censoring value{p_end}
{synopt:{cmd:e(iterate)}}maximum iterations{p_end}
{synopt:{cmd:e(tolerance)}}convergence tolerance{p_end}
{synopt:{cmd:e(N_weight_strata)}}observed joint (censoring x entry) weight strata{p_end}
{synopt:{cmd:e(min_weight_prob)}}smallest weight probability A the scan consulted{p_end}
{synopt:{cmd:e(max_lt_weight)}}largest retained subject-by-cause-time weight{p_end}
{synopt:{cmd:e(N_prob_warn)}}consulted weight probabilities with A < 1e-10{p_end}
{synopt:{cmd:e(N_weight_warn)}}retained subject-by-cause-time weights above 1e6{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:finegray}{p_end}
{synopt:{cmd:e(cmdline)}}full estimation command as typed{p_end}
{synopt:{cmd:e(refitcmd)}}estimation command used by the {opt bootstrap()} refits{p_end}
{synopt:{cmd:e(predict)}}{cmd:finegray_predict}{p_end}
{synopt:{cmd:e(depvar)}}{cmd:_t} (the {cmd:stset} analysis time; as {helpb stcrreg}){p_end}
{synopt:{cmd:e(compete)}}competing events variable name{p_end}
{synopt:{cmd:e(compete_values)}}values of {cmd:e(compete)} pooled as competing events{p_end}
{synopt:{cmd:e(designvars)}}design columns, one per estimated coefficient{p_end}
{synopt:{cmd:e(entryvar)}}entry-time column; only on multiple-record data{p_end}
{synopt:{cmd:e(idvar)}}the {cmd:stset} {opt id()} variable; empty if none{p_end}
{synopt:{cmd:e(mi_data)}}{cmd:1} if fitted on {cmd:mi} data; empty otherwise{p_end}
{synopt:{cmd:e(postest)}}{cmd:unavailable_mi} on such a fit; empty otherwise{p_end}
{synopt:{cmd:e(fvvarlist)}}typed factor-variable specification; with factors{p_end}
{synopt:{cmd:e(fvsemantic)}}factor-variable expansion semantics; with factors{p_end}
{synopt:{cmd:e(strata)}}censoring strata variables; only with {opt strata()}{p_end}
{synopt:{cmd:e(truncstrata)}}entry strata variables; only with {opt truncstrata()}{p_end}
{synopt:{cmd:e(bstrata)}}baseline strata variable; only with {opt bstrata()}{p_end}
{synopt:{cmd:e(bstrata_noevent)}}strata with no cause event; only with {opt bstrata()}{p_end}
{synopt:{cmd:e(bstrata_noevent_x)}}the same strata in {cmd:%21x}; only with {opt bstrata()}{p_end}
{synopt:{cmd:e(tvc)}}variables named in {opt tvc()}; only with {opt tvc()}{p_end}
{synopt:{cmd:e(tsplit)}}interior interval boundaries; only with {opt tvc()}{p_end}
{synopt:{cmd:e(tvc_covariates)}}design columns they resolved to; only with {opt tvc()}{p_end}
{synopt:{cmd:e(tvc_pos)}}their positions in {cmd:e(designvars)}; only with {opt tvc()}{p_end}
{synopt:{cmd:e(tsplit_nfail)}}cause events per interval; only with {opt tvc()}{p_end}
{synopt:{cmd:e(lt_weight)}}weight computed; see {help finegray##lt:Left truncation}{p_end}
{synopt:{cmd:e(lt_vce)}}variance computed under delayed entry{p_end}
{synopt:{cmd:e(bh_seq)}}serial number of the cached baseline curve{p_end}
{synopt:{cmd:e(bh_key)}}internal key to the cached baseline{p_end}
{synopt:{cmd:e(weight_warn_strata)}}joint-group codes flagged; only when one fired{p_end}
{synopt:{cmd:e(clustvar)}}cluster variable; if {cmd:cluster()} specified{p_end}
{synopt:{cmd:e(wtype)}}weight type ({cmd:pweight} or {cmd:fweight}); only with weights{p_end}
{synopt:{cmd:e(wexp)}}weight expression; only with weights{p_end}
{synopt:{cmd:e(wsig)}}weight-column digest; only with weights{p_end}
{synopt:{cmd:e(vce)}}variance estimation method{p_end}
{synopt:{cmd:e(vce_meat)}}which sandwich meat was used{p_end}
{synopt:{cmd:e(vce_adjust)}}finite-sample factor on {cmd:e(V)}: {cmd:finite_sample} or {cmd:none}{p_end}
{synopt:{cmd:e(title)}}Fine-Gray competing risks regression{p_end}
{synopt:{cmd:e(marginsok)}}{cmd:xb}; empty in the cases below{p_end}
{synopt:{cmd:e(properties)}}b V{p_end}
{synopt:{cmd:e(datasignature)}}signature of the estimation data{p_end}
{synopt:{cmd:e(datasignaturevars)}}variables covered by {cmd:e(datasignature)}{p_end}
{synopt:{cmd:e(sample)}}estimation-sample indicator{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector (log-SHR); base levels as zeros{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix; zero at base levels{p_end}
{synopt:{cmd:e(basehaz)}}baseline cumulative subhazard; only with {opt basehaz}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Under {cmd:fweight}s {cmd:e(N)}, {cmd:e(N_fail)}, {cmd:e(N_compete)} and {cmd:e(N_cens)} are the replicated
totals; {cmd:pweight}s leave every count at the number of subjects and carry the
weight total in {cmd:e(sum_w)}. {cmd:e(marginsok)} is empty under {opt tvc()} and on certain
purely continuous interaction fits. On a factor fit {cmd:e(b)} is wider than
{cmd:e(designvars)} by one zero column per base level; under {opt tvc()} it is wider by
one column per named covariate per extra interval.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
See {helpb finegray_methods} for the estimator and its computation, the
variance and the nuisance term, the refusal rationales, baseline strata,
time-varying effects, left truncation and the weight support boundaries, factor
variables and {cmd:margins}, multiple imputation, the cumulative incidence
construction, the proportionality diagnostic, the comparison with
{helpb stcrreg}, performance, and the full reference list with its citation
scope.

{pstd}
Fine JP, Gray RJ. A proportional hazards model for the subdistribution of a
competing risk. {it:JASA} 1999; 94(446): 496-509.

{pstd}{browse "https://doi.org/10.1080/01621459.1999.10474144":doi:10.1080/01621459.1999.10474144}{p_end}

{pstd}
Wogu AF, Zhao S, Nichols HB, Cai J. Proportional subdistribution hazards model
for competing risks in case-cohort
studies. {it:American Journal of Applied Mathematics} 2021; 9(5): 165-185.

{pstd}{browse "https://doi.org/10.11648/j.ajam.20210905.12":doi:10.11648/j.ajam.20210905.12}{p_end}


{marker author}{...}
{title:Author}

{pstd}Timothy P Copeland, Karolinska Institutet{p_end}
{pstd}Version 1.3.2, 2026-09-08{p_end}

{pstd}Report bugs and suggestions at{break}
{browse "https://github.com/tpcopeland/Stata-Tools":https://github.com/tpcopeland/Stata-Tools}{p_end}


{title:Also see}

{psee}
Online: {helpb finegray_methods}, {helpb finegray_predict}, {helpb finegray_cif},
{helpb finegray_phtest}, {helpb stcrreg}, {helpb stcox}, {helpb stset}

{hline}
