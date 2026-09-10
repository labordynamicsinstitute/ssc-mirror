{smcl}
{vieweralsosee "finegray" "help finegray"}{...}
{vieweralsosee "finegray_methods" "help finegray_methods"}{...}
{vieweralsosee "finegray_cif" "help finegray_cif"}{...}
{vieweralsosee "finegray_phtest" "help finegray_phtest"}{...}
{vieweralsosee "[ST] stcrreg" "help stcrreg"}{...}
{vieweralsosee "[ST] stcox" "help stcox"}{...}
{viewerjumpto "Syntax" "finegray_predict##syntax"}{...}
{viewerjumpto "Description" "finegray_predict##description"}{...}
{viewerjumpto "Options" "finegray_predict##options"}{...}
{viewerjumpto "Time-varying effects" "finegray_predict##tvc"}{...}
{viewerjumpto "Baseline strata" "finegray_predict##bstrata"}{...}
{viewerjumpto "Factor-variable alignment" "finegray_predict##fvalign"}{...}
{viewerjumpto "Examples" "finegray_predict##examples"}{...}
{viewerjumpto "Stored results" "finegray_predict##results"}{...}
{viewerjumpto "Author" "finegray_predict##author"}{...}
{title:Title}

{p2colset 5 28 30 2}{...}
{p2col:{cmd:finegray_predict} {hline 2}}Post-estimation predictions after finegray{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 28 2}
{cmd:finegray_predict}
{dtype}
{newvar}
{ifin}{cmd:,}
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt xb}}linear predictor z'beta (default){p_end}
{synopt:{opt cif}}cumulative incidence function{p_end}
{synopt:{opt sch:oenfeld}}Schoenfeld residuals at cause-event times{p_end}
{synopt:{opt basecsh:azard}}baseline cumulative subdistribution hazard H0(t){p_end}
{synopt:{opth time:var(varname)}}use {it:varname} instead of {cmd:_t} for time{p_end}
{synopt:{opt att:ime(#)}}evaluate {opt xb} at time {it:#} (tvc fits){p_end}
{synopt:{opt ci}}also generate CIF confidence limits{p_end}
{synopt:{opt boot:strap(#)}}bootstrap {opt ci} limits from {it:#} subject resamples{p_end}
{synopt:{opt seed(#)}}random-number seed for {opt bootstrap()}{p_end}
{synopt:{opt l:evel(#)}}confidence level for {opt ci}; default {cmd:c(level)}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:finegray_predict} generates predictions after {helpb finegray}. Four
prediction types are available:

{phang2}
{bf:xb} (default) computes the linear predictor z'beta from the Fine-Gray
model coefficient vector.

{phang2}
{bf:cif} computes the cumulative incidence function: CIF(t|z) = 1 -
exp(-H0(t) * exp(z'beta)), where H0(t) is the fitted baseline cumulative
subdistribution hazard.

{phang2}
{bf:schoenfeld} computes Schoenfeld residuals at cause-event times. For a
model with p covariates, this creates p variables: {it:newvar} for the first
covariate, {it:newvar}{cmd:_2} through {it:newvar}{cmd:_}{it:p} for the
rest. Residuals are missing for non-cause-event observations.

{phang2}
{bf:basecshazard} computes H0(t), the baseline cumulative subdistribution
hazard, at each requested time.

{pstd}
Not available after a fit on {cmd:mi} data ({cmd:r(301)}); see
{help finegray##mi:Multiple imputation}. A converged fit is required
({cmd:r(430)} otherwise). Under delayed entry, predictions may move because the
fitted coefficients and baseline move; see
{help finegray##lt:Left truncation}.

{pstd}
{opt cif} evaluates the CIF at each observation's own {cmd:_t}; for a common
horizon, set a constant time variable and use {opt timevar()}. The {opt ci} and
{opt schoenfeld} paths verify that the estimation data are unchanged
({cmd:r(459)} otherwise). Point {opt xb} predictions remain available on
compatible new data, and point {opt cif} and {opt basecshazard} predictions too
while the fit still holds a resolvable baseline. See
{help finegray_methods##stcrreg:Comparison with stcrreg} and
{help finegray_methods##cif:Cumulative incidence}.


{marker options}{...}
{title:Options}

{phang}
{opt xb} computes the linear predictor z'beta. This is the default if none of
{opt cif}, {opt schoenfeld} or {opt basecshazard} is specified.

{phang}
{opt basecshazard} generates the baseline cumulative subdistribution hazard
H0(t), evaluated at each observation's analysis time ({cmd:_t}, or the variable
given in {opt timevar()}). This is the same quantity {helpb stcrreg} returns with
{cmd:predict, basecshazard}, and it is the recommended way to obtain the
baseline: it costs O(N), whereas {cmd:e(basehaz)} -- which holds the same curve as
a matrix with one row per event time -- is O(rows^2) to create and so is posted
only when {cmd:finegray}'s {opt basehaz} option is given. {opt ci} and
{opt bootstrap()} are not allowed with {opt basecshazard}: the baseline carries no
covariate profile, and a silently ignored {opt ci} would hand back a bare point
estimate that looks like a band. Because H0(t) does not depend on the
covariates, the data in memory need carry only the time variable -- and, after
a fit with {opt bstrata()}, the baseline strata variable. The model covariates
are not required and are not read.

{phang}
{opt cif} computes the cumulative incidence function (CIF) at each
observation's analysis time {cmd:_t} (or the time given by {opt timevar()}) --
one prediction per row, at that subject's follow-up time, not at a single
shared horizon. The CIF is computed as 1 - exp(-H0(t) * exp(z'beta)) using the
resolved fitted baseline, evaluated as a step function: for each observation,
H0 is read at the largest event time less than or equal to that observation's
time. The command uses the opt-in {cmd:e(basehaz)} matrix when present and
otherwise uses the active fit's cached or rebuilt baseline. To predict at a
fixed horizon for the whole sample, use {opt timevar()} with a constant time
variable. Where exp(z'beta) exceeds double precision at a finite linear
predictor, the CIF is evaluated to its limit: 1 once H0(t) is positive, and 0
before the first cause event; a missing covariate or time still gives a
missing prediction.

{marker tvc}{...}
{phang}
{opt attime(#)} fixes the analysis time at which the linear predictor is
evaluated. It requires {opt xb} and a fit made with
{helpb finegray##tvc:tvc()}; without {opt tvc()} the linear predictor does not
depend on time and there is nothing to evaluate it at, so {opt attime()} is
{cmd:r(198)} rather than a silently ignored option.

{phang}
{bf:After a fit with} {helpb finegray##tvc:tvc()}: {opt xb} becomes a function of time (scored at each row's
own {cmd:_t}; {opt attime(#)} scores at one time). {opt cif} accumulates the baseline interval
by interval. Both analytic {opt ci} and {opt bootstrap(#)} are available; the analytic
route is fixed-weight. {opt schoenfeld} is {bf:not available} ({cmd:r(198)}). See
{help finegray##tvc:Time-varying effects}.

{marker weights}{...}
{phang}
{bf:After a weighted fit}: {opt cif}, {opt basecshazard} and {opt ci} use the
weighted Breslow baseline and weighted influence function. The weight is
re-evaluated from {cmd:e(wexp)} and reconciled against {cmd:e(sum_w)}. See
{help finegray##weights:Weights}.

{marker bstrata}{...}
{phang}
{bf:After a fit with} {helpb finegray##bstrata:bstrata()}: {opt cif} and
{opt basecshazard} answer each row from its own stratum's baseline, so the
{cmd:bstrata()} variable must be in the data. A missing value gives a missing
prediction; a stratum with no cause event is {cmd:r(459)}. {opt xb} is
unaffected. See {help finegray##bstrata:Baseline strata}.

{phang}
{opt sch:oenfeld} computes Schoenfeld residuals at cause-event times. For
a model with {it:p} covariates, {it:p} variables are created: {it:newvar}
contains residuals for the first covariate, and {it:newvar}{cmd:_2}
through {it:newvar}{cmd:_}{it:p} contain residuals for the remaining
covariates. Because the suffix is part of the created name, a
one-covariate model allows a 32-character {it:newvar}; with multiple
covariates, its maximum length is 32 - 1 - length(string({it:p}))
characters (30 for 2-9 terms, 29 for 10-99, and so on). An over-long stub
is refused with {cmd:r(198)} before any residual is computed. Residuals
are set to missing for observations that are not cause-of-interest
events. {opt timevar()} is not allowed with {opt schoenfeld} and is
rejected with {cmd:r(198)}; residuals are computed at the original event
times. The residuals match {helpb stcrreg}'s {cmd:predict, schoenfeld}
exactly at untied event times; at a tied event time the per-event split
follows {cmd:finegray}'s own convention but preserves the per-time
total; see {help finegray_methods##stcrreg:Comparison with stcrreg}.

{phang}
{opth timevar(varname)} specifies a variable to use as the time axis instead
of {cmd:_t}. It applies to {opt cif} and {opt basecshazard} only and is
refused with {cmd:r(198)} alongside {opt xb} or {opt schoenfeld}: {opt xb}
reads no time at all on a proportional fit (use {opt attime()} after a
{opt tvc()} fit), and {opt schoenfeld} residuals are defined at the original
cause-event times. This is useful for generating predictions at specific time
points or when the data are not currently {cmd:stset}. For {opt cif}, a constant
variable set to a target horizon (e.g. {cmd:gen t5 = 5}) yields each subject's
predicted CIF at that horizon.

{phang}
{opt ci} (with {opt cif}) additionally generates {it:newvar}{cmd:_lci} and
{it:newvar}{cmd:_uci}, the lower and upper confidence limits for each
predicted CIF. The suffixes are part of the created names, so with
{opt ci} the {it:newvar} may be at most 28 characters; an over-long name
is refused with {cmd:r(198)} before any prediction is computed. Limits use
an influence-function (sandwich) standard error and are formed on the
complementary log-log scale so they remain inside (0,1). Because the
influence functions require the original estimation data, {opt ci}
restricts the prediction to the estimation sample ({cmd:e(sample)}) and
needs {cmd:_t} in memory. The standard error treats the
inverse-probability-of-censoring weights and, under delayed entry, the
entry weights as fixed, so it omits weight-estimation variability; see
{help finegray_methods##cif:Cumulative incidence}. For pointwise
confidence limits over a grid of times, or a fixed-horizon table for a
covariate profile, see {helpb finegray_cif}.

{phang}
{opt bootstrap(#)} (with {opt ci}) computes the confidence limits by resampling
subjects with replacement and refitting instead of using the analytic
influence-function SE. If the original fit specified {opt cluster()}, whole
clusters are resampled instead. Nonconverged refits, and refits whose resample
loses a factor level, are skipped (a note reports how many). At least 25
replications must be requested, and at least 25 must succeed, or
{cmd:finegray_predict} exits with an error; see
{help finegray_methods##cif:Cumulative incidence}. The refit is run on the
estimation sample, so any {cmd:if} or {cmd:in} qualifier used at fit time does
not apply to the replications. Each replication re-estimates the model and its
censoring weights; under delayed entry it also re-estimates the entry weights
and weight strata. Point predictions are unchanged, and the original {cmd:e()}
results and {cmd:e(sample)} are preserved.

{phang}
{opt bootstrap()} is refused ({cmd:r(198)}) after a fit with
{cmd:[fweight=}{it:exp}{cmd:]}: {helpb bsample} resamples rows, and an
fweighted fit stores its replication in a weight column rather than in rows, so
the replicate SD would describe a much smaller design than the fit. The
analytic {opt ci} is exact under frequency weights -- an fweighted fit is the
fit of the replicated data -- so use it, or {helpb expand} the data by the
weight and bootstrap the expanded fit. {cmd:[pweight=}{it:exp}{cmd:]} fits are
unaffected.

{phang}
{opt seed(#)} sets the random-number seed used by {opt bootstrap()}. It requires
{opt bootstrap()}, and must be an integer between {cmd:0} and {cmd:2147483647}.

{phang}
{opt level(#)} sets the confidence level for {opt ci}; the default is
{cmd:c(level)}, which is initially 95; the setting can be changed by
{helpb set level} and must be between 10 and 99.99 inclusive, with at most
two decimal places -- the same rule {cmd:finegray} itself applies.

{marker fvalign}{...}
{pstd}
{bf:Factor variables:} Predictions are aligned to the current data by level
{bf:value}, not position. An observation at a level the fit never saw is
{cmd:r(459)}, not silently collapsed onto the base. {cmd:xb} honours the
{cmd:predict} contract {helpb margins} relies on. See
{help finegray_methods##fv:Factor variables and margins}.


{marker emptyresult}{...}
{pstd}
{bf:Empty results are refused, not committed:} a prediction that can be
computed for no observation is an error rather than a column of missing
values. {opt cif} exits {cmd:r(2000)} when no observation in the prediction
sample can be scored -- for example when a covariate in the fit is missing on
every one of those rows -- and {opt ci} exits {cmd:r(2000)} when the
complementary log-log limits are undefined everywhere, which is what a
cumulative incidence that is identically zero at the requested horizon (a time
before the first cause event) produces. The refusal removes any variable the
command had already created, so the data are left exactly as they were.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Setup}

{phang2}{cmd:. webuse hypoxia, clear}{p_end}
{phang2}{cmd:. gen byte status = failtype}{p_end}
{phang2}{cmd:. stset dftime, failure(dfcens==1) id(stnum)}{p_end}
{phang2}{cmd:. finegray ifp tumsize pelnode, compete(status) cause(1)}{p_end}

{pstd}
{bf:Linear predictor (default)}

{phang2}{cmd:. finegray_predict xb_hat, xb}{p_end}

{pstd}
{bf:Cumulative incidence function}

{phang2}{cmd:. finegray_predict cif_hat, cif}{p_end}

{pstd}
{bf:CIF with explicit storage type}

{phang2}{cmd:. finegray_predict double cif_precise, cif}{p_end}
{phang2}{cmd:. summarize cif_precise}{p_end}

{pstd}
{bf:CIF at custom time points}

{phang2}{cmd:. gen double mytime = 5}{p_end}
{phang2}{cmd:. finegray_predict cif_at5, cif timevar(mytime)}{p_end}

{pstd}5-year CIF with a confidence interval for each subject{p_end}
{phang2}{cmd:. gen double mytime_ci = 5}{p_end}
{phang2}{cmd:. finegray_predict cif5, cif timevar(mytime_ci) ci}{p_end}
{phang2}{cmd:. list cif5 cif5_lci cif5_uci in 1/5}{p_end}

{pstd}5-year CIF with bootstrap confidence limits{p_end}
{phang2}{cmd:. gen double mytime_bs = 5}{p_end}
{phang2}{cmd:. finegray_predict cif5_bs, cif timevar(mytime_bs) ci bootstrap(200) seed(12345)}{p_end}

{pstd}
{bf:Baseline cumulative subdistribution hazard}

{phang2}{cmd:. finegray_predict basech, basecshazard}{p_end}
{phang2}{cmd:. summarize basech}{p_end}

{pstd}
{bf:Schoenfeld residuals}

{phang2}{cmd:. finegray_predict sch, schoenfeld}{p_end}
{phang2}{cmd:. list sch* in 1/5}{p_end}

{pstd}
{bf:After a tvc() fit the linear predictor is a function of time.} Without
{opt attime()} each row is scored at its own {cmd:_t}; with it, every row is
scored at one common time.

{phang2}{cmd:. finegray ifp tumsize pelnode, compete(status) cause(1) tvc(pelnode) tsplit(1)}{p_end}
{phang2}{cmd:. finegray_predict xb_own, xb}{p_end}
{phang2}{cmd:. finegray_predict xb_at2, xb attime(2)}{p_end}
{phang2}{cmd:. summarize xb_own xb_at2}{p_end}

{pstd}
{bf:After a stratified-baseline fit}: each row is scored from its own stratum's
baseline

{phang2}{cmd:. finegray ifp tumsize, compete(status) cause(1) bstrata(pelnode)}{p_end}
{phang2}{cmd:. finegray_predict h0_s, basecshazard}{p_end}
{phang2}{cmd:. finegray_predict cif_s, cif}{p_end}
{phang2}{cmd:. tabstat h0_s cif_s, by(pelnode) stat(min max)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:finegray_predict} creates one or more variables but does not store results
in {cmd:r()} or {cmd:e()}. The variables are labeled:

{phang2}{cmd:xb}: "Linear prediction (xb)"; after a {opt tvc()} fit the
evaluation basis is appended -- "Linear prediction (xb) at _t", or
"Linear prediction (xb) at t = {it:#}" with {opt attime(#)}{p_end}
{phang2}{cmd:cif}: "CIF at {it:tvar} (cause {it:#})", where {it:tvar} is
{cmd:_t} or the {opt timevar()} variable and {it:#} is the cause of interest the
fit was estimated for - so the label records both the cause and the horizon each
prediction was evaluated at{p_end}
{phang2}{it:newvar}{cmd:_lci}: "CIF lower {it:level}% limit"{p_end}
{phang2}{it:newvar}{cmd:_uci}: "CIF upper {it:level}% limit"{p_end}
{phang2}{cmd:basecshazard}: "Baseline cumulative subhazard"{p_end}
{phang2}{cmd:schoenfeld}: "Schoenfeld residual: {it:term}" for each design
column, where {it:term} is the term exactly as the fit spells it --
{cmd:ifp} for a plain covariate, {cmd:1.pelnode} for a factor indicator,
{cmd:1.pelnode#c.ifp} for an interaction, which is also the spelling
{helpb finegray_phtest} reports{p_end}


{marker author}{...}
{title:Author}

{pstd}Timothy P Copeland, Karolinska Institutet{p_end}

{pstd}Report bugs and suggestions at{break}
{browse "https://github.com/tpcopeland/Stata-Tools":https://github.com/tpcopeland/Stata-Tools}{p_end}


{title:Also see}

{psee}
Online: {helpb finegray}, {helpb finegray_methods}, {helpb finegray_cif},
{helpb finegray_phtest}, {helpb stcrreg}, {helpb stcox}, {helpb stset}

{hline}
