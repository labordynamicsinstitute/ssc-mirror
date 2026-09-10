{smcl}
{vieweralsosee "finegray" "help finegray"}{...}
{vieweralsosee "finegray_methods" "help finegray_methods"}{...}
{vieweralsosee "finegray_predict" "help finegray_predict"}{...}
{vieweralsosee "finegray_phtest" "help finegray_phtest"}{...}
{vieweralsosee "stcurve" "help stcurve"}{...}
{viewerjumpto "Syntax" "finegray_cif##syntax"}{...}
{viewerjumpto "Description" "finegray_cif##description"}{...}
{viewerjumpto "Options" "finegray_cif##options"}{...}
{viewerjumpto "Baseline strata" "finegray_cif##bstratum"}{...}
{viewerjumpto "Overlaid curves" "finegray_cif##over"}{...}
{viewerjumpto "Time-varying effects" "finegray_cif##tvc"}{...}
{viewerjumpto "Remarks" "finegray_cif##remarks"}{...}
{viewerjumpto "Examples" "finegray_cif##examples"}{...}
{viewerjumpto "Stored results" "finegray_cif##results"}{...}
{viewerjumpto "Author" "finegray_cif##author"}{...}
{title:Title}

{phang}
{bf:finegray_cif} {hline 2} Cumulative incidence curves and fixed-horizon
cumulative incidence after {help finegray}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:finegray_cif}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt at(var=# ...)}}covariate profile for the curve{p_end}
{synopt :{opth over(varname)}}one curve per level, overlaid{p_end}
{synopt :{opt att:ime(numlist)}}table of the CIF at the listed horizons{p_end}
{synopt :{opt ti:mepoints(numlist)}}evaluate the curve at these times{p_end}
{synopt :{opt bstrat:um(#)}}baseline stratum; required after {cmd:bstrata()}{p_end}
{synopt :{opt ci}}add pointwise confidence limits{p_end}
{synopt :{opt boot:strap(#)}}bootstrap the confidence band with {it:#} resamples{p_end}
{synopt :{opt seed(#)}}random-number seed for {opt bootstrap()}{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:c(level)}{p_end}
{synopt :{opt sav:ing(filename[, replace])}}save the numeric estimates{p_end}
{synopt :{opt nograph}}suppress the graph{p_end}
{synopt :{it:twoway_options}}any options documented in {help twoway_options}{p_end}
{synoptline}
{p 4 6 2}{cmd:finegray_cif} is for use after {helpb finegray}; see
{helpb finegray}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:finegray_cif} computes the predicted cumulative incidence function (CIF)
for a chosen covariate profile after {helpb finegray}. The command uses
{cmd:e(basehaz)} when that opt-in matrix exists and otherwise resolves the
fit-specific cached or rebuilt baseline; the construction is in
{help finegray_methods##cif:Cumulative incidence}.

{pstd}
By default it plots the CIF as a right-continuous step function, thinned to at
most 401 points when the baseline is dense; use {opt timepoints()} for an exact
grid. With {opt attime()} it reports the CIF at specific horizons
instead. {opt over(varname)} draws one curve per level of a model variable or
baseline stratum; see {help finegray_cif##over:Overlaid curves}. The covariate profile is always
reported in an {cmd:at:} line and graph note. The curve extends to the end of
follow-up, and times outside the support are flagged. See
{help finegray_methods##cif:Cumulative incidence}.

{pstd}
The command requires the unchanged {cmd:stset} estimation data. A converged fit
is required ({cmd:r(430)} otherwise). Not available after a fit on {cmd:mi}
data ({cmd:r(301)}); see {help finegray##mi:Multiple imputation}.

{marker options}{...}
{title:Options}

{phang}
{opt at(var=# ...)} sets the covariate profile at which the CIF is evaluated, for
example {cmd:at(age=60 male=1)}. Variables not listed are held at their
estimation-sample mean, which is also the default profile. After a weighted fit
that mean is the WEIGHTED estimation-sample mean, taken under the fit's own
{cmd:[pweight=]}/{cmd:[fweight=]} column: an {cmd:fweight} fit therefore reports
the same default curve as the fit of the {helpb expand}ed data. A factor
indicator's default is its weighted sample proportion, sum(w | level) / sum(w).

{phang2}
Factor variables are named directly by their level, for example
{cmd:at(pelnode=1)} after {cmd:finegray i.pelnode ...}; the reference level
({cmd:at(pelnode=0)}) leaves every indicator at 0. A variable that enters an
interaction may be set the same way: the setting is carried into every design
column the variable appears in, so after
{cmd:finegray i.pelnode c.ifp i.pelnode#c.ifp}, {cmd:at(pelnode=1 ifp=20)}
evaluates the interaction at {cmd:1 * 20 = 20}, and {cmd:at(pelnode=0 ifp=20)}
evaluates it at 0. Where a term mixes a variable you set with one you do not,
the unset part is held at its estimation-sample mean (weighted, on a weighted
fit). A design column that contains no variable you set keeps its own
estimation-sample mean.

{phang2}
The package-owned design columns in {cmd:e(designvars)} may still be set by
name, for example {cmd:at(_fg_pelnode_1Xifp=0)}, and such a setting is applied
after, and therefore overrides, anything implied by the variables you named.

{marker over}{...}
{phang}
{opt over(varname)} draws one curve per level of {it:varname} in a single
call. {it:varname} is either a model variable (a factor variable such as
{cmd:pelnode} after {cmd:i.pelnode}, or a variable entered directly such as
{cmd:ccr5} after {cmd:finegray ccr5 ...}) or the {opt bstrata()} variable of
the fit.

{pmore}
For a model variable, one curve is evaluated at each distinct
estimation-sample value of {it:varname}, with every other covariate held as {opt at()}
says (or at its estimation-sample mean, weighted on a weighted fit); a variable that enters an interaction
is carried into every design column it appears in, exactly as {opt at()} does. Each
curve is the same computation as the standalone call
{cmd:finegray_cif, at(}{it:varname}{cmd:=}{it:level}{cmd: ...)} and agrees with it bit for bit. {it:varname} may
not also be set in {opt at()}, and a variable with more than 20 distinct values is
refused with {cmd:r(198)}: the overlay is for a grouping variable, and a continuous
covariate is drawn at chosen values with {opt at()}.

{pmore}
The bit-for-bit agreement holds at the machine value of the level, not at its
printed spelling. Levels are carried into the per-curve {opt at()} in
hexadecimal-double ({cmd:%21x}) form, which Stata's numeric parser reads back
exactly; the levels {cmd:r(levels)} and the row names of {cmd:r(at)} report are
the ordinary display renderings and round a noninteger level in the last bit or
two. To reproduce one curve of an overlay by hand, take the level from
{cmd:r(levels_mat)} (or type it in {cmd:%21x}), not from the printed list.

{pmore}
For the {opt bstrata()} variable, one curve is drawn per fitted baseline stratum,
each the same computation as {cmd:finegray_cif, bstratum(#)}; a stratum that carried
no cause event has no curve and is omitted with a note. {opt over()} then stands in
for {opt bstratum()}, and the two may not be combined.

{pmore}
With {opt attime()} one table is printed per curve; otherwise the curves are
overlaid on one graph, each confidence band (with {opt ci}) shaded in its own
curve's color, with a legend entry per level (the value label where one is
defined). {cmd:r(table)} gains a sixth column, {cmd:over}, holding each row's level, {cmd:r(at)}
has one row per curve, and the {opt saving()} dataset gains an {cmd:over} variable
carrying the source variable's value label; {cmd:r(over)} and {cmd:r(levels)} name the
variable and the levels drawn. With {opt bootstrap()} the replications are shared
across the curves (one refit scores every profile), counted per curve, and
{cmd:r(bootstrap_success)} reports the smallest count; a note lists the per-curve
counts when they differ.

{phang}
{opt attime(numlist)} requests a table of the CIF at the listed time horizons
(for example {cmd:attime(1 5 10)}) instead of a plotted curve. Combine with
{opt ci} to include confidence limits. May not be combined with
{opt timepoints()}. Horizons are used exactly as typed, to full double
precision: the CIF is a step function, so a horizon at a cause-event time
includes that event and one an ulp before it does not. Repeated horizons are
collapsed to one row; horizons that differ in any digit are separate rows.

{phang}
{opt timepoints(numlist)} evaluates the curve at the specified times rather than
at the distinct cause-event times of the fitted baseline. May not be combined
with {opt attime()}: both name the times the CIF is evaluated at, and
{opt attime()} additionally selects table output over a plotted curve, so the
combination is refused rather than resolved silently. Unlike the default grid,
the requested grid is not thinned. Times are used exactly as typed, as for
{opt attime()}.

{marker tvc}{...}
{phang}
{bf:After a fit with} {helpb finegray##tvc:tvc()} the CIF is accumulated
interval by interval. Both analytic {opt ci} and {opt bootstrap(#)} are
available; the analytic route is fixed-weight. See
{help finegray_methods##tvc:Time-varying effects}.

{marker bstratum}{...}
{phang}
{opt bstratum(#)} names the baseline stratum the CIF belongs to. {bf:Required}
when the fit has more than one baseline stratum ({cmd:e(k_bstrata)} > 1), since
a covariate profile alone no longer identifies a curve there. It is refused
({cmd:r(198)}) after every other fit -- including a {opt bstrata()} fit with a
single stratum, which is the unstratified estimator bit for bit and has no
stratum to name. A value with no estimation-sample subjects or no cause events
is {cmd:r(459)}. Use {opt over()}
on the {opt bstrata()} variable for all strata at once. See
{help finegray_methods##bstrata:Baseline strata}.

{phang}
{opt ci} adds pointwise confidence limits. The standard error of the CIF is an
influence-function (sandwich) standard error; limits are formed on the
complementary log-log scale so that they remain inside (0,1). The standard error
treats the fitted weight functions as known, so under heavy censoring or delayed
entry it can omit weight-estimation variability; {opt bootstrap()}
re-estimates the weight functions in each replication. See
{help finegray_methods##cif:Cumulative incidence}. Limits are reported only
where 0 < CIF < 1 and the standard error is positive. At a profile so extreme
that exp(xb) exceeds double precision, the CIF is 1 and its standard error 0 to
machine precision (the limit of the estimator at that profile, the same values
returned one step short of the overflow) and a note says so; a profile whose
linear predictor is not finite is refused.

{phang}
{opt bootstrap(#)} computes pointwise confidence limits by resampling
subjects with replacement and refitting the model. It requires
{opt ci}. If the original fit specified {opt cluster()}, whole clusters
are resampled. The resulting limits therefore follow the fitted resampling
unit and include variability from re-estimating the censoring
weights. Under delayed entry it also re-estimates the entry weights and
weight strata. Nonconverged refits, and refits whose resample loses a
factor level (so the coefficient vector no longer matches the stored
covariate profile), are skipped and counted in
{cmd:r(bootstrap_failed)}. At least 25 replications must be requested, and
at least 25 must succeed, or {cmd:finegray_cif} exits with an error; see
{help finegray_methods##cif:Cumulative incidence}. The refit is run on the
estimation sample, so any {cmd:if} or {cmd:in} qualifier used at fit time
does not apply to the replications. Point estimates are unchanged; only
the standard error and limits differ. The original estimation results and
{cmd:e(sample)} are preserved.

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
{opt seed(#)} sets the random-number seed used by {opt bootstrap()} for
reproducibility. It requires {opt bootstrap()}, and must be an integer between
{cmd:0} and {cmd:2147483647}.

{phang}
{opt level(#)} sets the confidence level for {opt ci}; it requires {opt ci}. The
default is {cmd:c(level)}, which is initially 95 and can be changed by
{helpb set level}. The value must be between 10 and 99.99 inclusive, with at
most two decimal places -- the same rule {cmd:finegray} itself applies.

{phang}
{opt saving(filename[, replace])} writes a dataset containing {cmd:time},
{cmd:cif}, {cmd:se}, {cmd:lci}, and {cmd:uci} (one row per evaluated time), plus
{cmd:over} with {opt over()} - the analogue of {cmd:outfile} after
{cmd:stcurve}. Only the optional suboption
{cmd:replace} is accepted. Shell metacharacters and embedded quote characters
are rejected in {it:filename}. Every variable is labelled, the dataset label
names the cause, and a dataset {helpb notes:note} records the covariate profile,
so the exported file documents itself. {cmd:finegray_cif} confirms the write
once, naming the path actually written (including a {cmd:.dta} extension it
supplied).

{phang}
{opt nograph} suppresses the graph (useful with {opt saving()}).

{phang}
{it:twoway_options} are any of the options documented in {help twoway_options},
for example {cmd:title()}, {cmd:xtitle()}, or {cmd:scheme()}. These pass through
to the CIF plot and override the defaults. In {opt attime()} mode no graph is
drawn, so these options are ignored with a note. The legend defaults to a
single
row; because repeated {cmd:legend()} options merge, you can adjust or suppress
it from here, for example {cmd:legend(off)}, {cmd:legend(pos(6))}, or
{cmd:legend(rows(2))}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Left truncation.} Delayed-entry CIF estimates use the ZZF Weight-1 contract
and move relative to earlier versions and to {helpb stcrreg}. See
{help finegray##lt:Left truncation}.

{pstd}
For per-subject CIF limits, see {helpb finegray_predict}{cmd:, cif ci}. With
{opt cluster()}, the analytic band uses the cluster-robust variance and
{opt bootstrap()} resamples whole clusters.

{pstd}
{bf:Weights.} After a weighted fit, the curve uses the weighted Breslow
baseline and the band uses the weighted influence function. The weight is
re-evaluated from {cmd:e(wexp)} and reconciled against {cmd:e(sum_w)}. See
{help finegray##weights:Weights}.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse hypoxia, clear}{p_end}
{phang2}{cmd:. gen byte status = failtype}{p_end}
{phang2}{cmd:. stset dftime, failure(dfcens==1) id(stnum)}{p_end}
{phang2}{cmd:. finegray i.pelnode ifp tumsize, compete(status) cause(1)}{p_end}

{pstd}Plot the CIF curve at the covariate means, with a 95% band{p_end}
{phang2}{cmd:. finegray_cif, ci}{p_end}

{pstd}Curve for a specified covariate profile{p_end}
{phang2}{cmd:. finegray_cif, at(pelnode=1 ifp=20 tumsize=5) ci}{p_end}

{pstd}Fixed-horizon table: CIF at 1, 5, and 8 years with confidence limits{p_end}
{phang2}{cmd:. finegray_cif, attime(1 5 8) ci}{p_end}

{pstd}Curve for a profile of an interaction model{p_end}
{phang2}{cmd:. finegray i.pelnode c.ifp i.pelnode#c.ifp tumsize, compete(status) cause(1)}{p_end}
{phang2}{cmd:. finegray_cif, at(pelnode=1 ifp=20) attime(1 5) ci}{p_end}

{pstd}Curve evaluated on a custom time grid{p_end}
{phang2}{cmd:. finegray_cif, timepoints(1 2 3 4 5 6 7 8) ci}{p_end}

{pstd}Save the numeric estimates behind the curve{p_end}
{phang2}{cmd:. finegray_cif, ci nograph saving(cifcurve.dta,replace)}{p_end}

{pstd}
{bf:One curve per exposure group.} {opt over()} draws every level of a model
variable in one call: a table per level with {opt attime()}, or one graph with
a legend. Here on {cmd:webuse hiv_si}, the data of {bf:[ST] stcrreg} example 4.

{phang2}{cmd:. webuse hiv_si, clear}{p_end}
{phang2}{cmd:. gen byte any_event = status > 0}{p_end}
{phang2}{cmd:. stset time, failure(any_event==1) id(patnr)}{p_end}
{phang2}{cmd:. finegray ccr5, compete(status) cause(2)}{p_end}
{phang2}{cmd:. finegray_cif, over(ccr5) attime(2 5 10) ci}{p_end}
{phang2}{cmd:. finegray_cif, over(ccr5) ci}{p_end}

{pstd}
The same on a factor variable with an interaction, holding the other covariate
at a chosen value; the setting is carried into the interaction column on each
curve.

{phang2}{cmd:. webuse hypoxia, clear}{p_end}
{phang2}{cmd:. gen byte status = failtype}{p_end}
{phang2}{cmd:. stset dftime, failure(dfcens==1) id(stnum)}{p_end}
{phang2}{cmd:. finegray i.pelnode c.ifp i.pelnode#c.ifp tumsize, compete(status) cause(1)}{p_end}
{phang2}{cmd:. finegray_cif, over(pelnode) at(ifp=20) ci}{p_end}

{pstd}Band by subject bootstrap{p_end}
{phang2}{cmd:. finegray_cif, attime(1 5 8) ci bootstrap(500) seed(12345)}{p_end}

{pstd}After a fit with baseline strata: one curve per stratum, or all strata at once{p_end}
{phang2}{cmd:. finegray ifp tumsize, compete(status) cause(1) bstrata(pelnode)}{p_end}
{phang2}{cmd:. finegray_cif, attime(1 5) bstratum(0) ci}{p_end}
{phang2}{cmd:. finegray_cif, attime(1 5) bstratum(1) ci}{p_end}
{phang2}{cmd:. finegray_cif, over(pelnode) ci}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:finegray_cif} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(level)}}confidence level; always posted; default c(level){p_end}
{synopt:{cmd:r(cause)}}cause of interest{p_end}
{synopt:{cmd:r(bootstrap_requested)}}requested replications; with {cmd:bootstrap()}{p_end}
{synopt:{cmd:r(bootstrap_success)}}converged replications used; with {cmd:bootstrap()}{p_end}
{synopt:{cmd:r(bootstrap_failed)}}skipped replications; with {cmd:bootstrap()}{p_end}
{synopt:{cmd:r(bstratum)}}baseline stratum evaluated; with {cmd:bstratum()}{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(profile_vars)}}model covariates, in column order of {cmd:r(at)}{p_end}
{synopt:{cmd:r(bstrata)}}baseline strata variable; with {cmd:bstratum()}/{cmd:over()}{p_end}
{synopt:{cmd:r(over)}}overlay variable; with {cmd:over()}{p_end}
{synopt:{cmd:r(levels)}}levels drawn, row order of {cmd:r(at)}; with {cmd:over()}{p_end}
{synopt:{cmd:r(se_method)}}how column 3 of {cmd:r(table)} was computed{p_end}
{synopt:{cmd:r(vce_adjust)}}always {cmd:none}; see {cmd:e(vce_adjust)}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}one row per evaluated time and curve{p_end}
{synopt:{cmd:r(at)}}covariate profile(s), one row per curve{p_end}
{synopt:{cmd:r(levels_mat)}}levels drawn, exact values; with {cmd:over()}{p_end}

{pstd}
The columns of {cmd:r(table)} are {cmd:time}, {cmd:cif}, {cmd:se},
{cmd:lci}, and {cmd:uci}; with {opt over()} a sixth column, {cmd:over}, holds
the level (or baseline stratum) each row belongs to, and the rows of
{cmd:r(at)} are named by level.

{pstd}
{cmd:r(levels)} and the row names of {cmd:r(at)} are display spellings and are
meant to be read; {cmd:r(levels_mat)} and the {cmd:over} column of
{cmd:r(table)} carry the same levels as machine doubles and are the forms to
compare or feed back into {opt at()}/{opt bstratum()}.

{marker author}{...}
{title:Author}

{pstd}Timothy P Copeland, Karolinska Institutet{p_end}

{pstd}Report bugs and suggestions at{break}
{browse "https://github.com/tpcopeland/Stata-Tools":https://github.com/tpcopeland/Stata-Tools}{p_end}


{title:Also see}

{psee}
Online: {helpb finegray}, {helpb finegray_methods}, {helpb finegray_predict},
{helpb finegray_phtest}, {helpb stcurve}, {helpb stcrreg}

{hline}
