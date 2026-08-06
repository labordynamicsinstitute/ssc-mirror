{smcl}
{* *! version 1.0.0  05aug2026}{...}
{vieweralsosee "causalimpact methods" "help causalimpact_methods"}{...}
{vieweralsosee "causalimpact interpretation" "help causalimpact_interpretation"}{...}
{vieweralsosee "causalimpact rcheck" "help causalimpact_rcheck"}{...}
{vieweralsosee "causalimpact postestimation" "help causalimpact_postestimation"}{...}
{viewerjumpto "Syntax" "causalimpact##syntax"}{...}
{viewerjumpto "Description" "causalimpact##description"}{...}
{viewerjumpto "Options" "causalimpact##options"}{...}
{viewerjumpto "Interpreting the output" "causalimpact##output"}{...}
{viewerjumpto "Remarks and practical guidance" "causalimpact##remarks"}{...}
{viewerjumpto "Compatibility with the R package" "causalimpact##rcompat"}{...}
{viewerjumpto "Examples" "causalimpact##examples"}{...}
{viewerjumpto "Stored results" "causalimpact##results"}{...}
{viewerjumpto "References" "causalimpact##references"}{...}
{viewerjumpto "Author" "causalimpact##author"}{...}

{title:Title}

{phang}
{bf:causalimpact} {hline 2} Causal impact of an intervention on a time series
using a Bayesian structural time-series model


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:causalimpact}
{depvar}
[{it:covariates}]
{ifin}{cmd:,}
{opth pre:period(numlist)}
{opth post:period(numlist)}
[{it:options}]

{pstd}
The data must be {helpb tsset} as a single time series (not {helpb xtset}).
{it:depvar} is the treated series; {it:covariates} are untreated control series
from which the synthetic control is built. {it:depvar} may contain missing
values; the covariates may not.

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Periods (required)}
{synopt:{opth pre:period(numlist)}}first and last time point of the
pre-intervention (training) period, in the units of the {help tsset} time
variable{p_end}
{synopt:{opth post:period(numlist)}}first and last time point of the
post-intervention period whose effect is to be measured{p_end}

{syntab:MCMC}
{synopt:{opt nit:er(#)}}number of MCMC draws; default {cmd:niter(1000)}{p_end}
{synopt:{opt burn:in(#)}}burn-in draws to discard; default is
{cmd:0.1*niter()}{p_end}
{synopt:{opt seed(#)}}random-number seed; sets {helpb set seed}{p_end}
{synopt:{opt nodots}}suppress the progress dots{p_end}

{syntab:State model}
{synopt:{opt priorl:evelsd(#)}}prior standard deviation of the local-level
random walk, in units of the data standard deviation; default
{cmd:priorlevelsd(0.01)}{p_end}
{synopt:{opt nse:asons(#)}}period of the seasonal component; default
{cmd:nseasons(1)} means no seasonal component{p_end}
{synopt:{opt seasond:uration(#)}}number of time points each season spans;
default {cmd:seasonduration(1)}{p_end}
{synopt:{opt dyn:amicregression}}use time-varying rather than static regression
coefficients{p_end}
{synopt:{opt nostand:ardize}}do not standardise the columns using pre-period
moments{p_end}
{synopt:{opt nocon:stant}}omit the intercept from the regression component{p_end}

{syntab:Spike-and-slab prior}
{synopt:{opt models:ize(#)}}expected number of covariates in the model,
{it:M} in eq. (2.9); default {cmd:modelsize(3)}{p_end}
{synopt:{opt r2(#)}}expected R-squared of the regression, used to set the
residual-variance prior; default {cmd:r2(0.8)}{p_end}
{synopt:{opt priord:f(#)}}prior degrees of freedom for the residual variance,
{it:nu_eps} in eq. (2.11); default {cmd:priordf(50)}{p_end}
{synopt:{opt ginf:o(#)}}Zellner g in eq. (2.12); default {cmd:ginfo(0.01)}{p_end}
{synopt:{opt dshr:inkage(#)}}diagonal shrinkage 1-{it:w} in eq. (2.12); default
{cmd:dshrinkage(0.5)}{p_end}
{synopt:{opt maxf:lips(#)}}number of inclusion indicators to attempt to flip per
sweep; default {cmd:maxflips(-1)} means all of them{p_end}
{synopt:{opt sigmau:pper(#)}}upper limit on the residual standard deviation, in
units of the data standard deviation; default is no limit{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}credible-interval level; default {cmd:level(95)}{p_end}
{synopt:{opt al:pha(#)}}tail-area probability, the R spelling of
{cmd:level()}; default {cmd:alpha(0.05)}{p_end}
{synopt:{opt rep:ort}}print the verbal interpretation of the results{p_end}
{synopt:{opt di:gits(#)}}rounding used in the verbal report; default
{cmd:digits(2)}{p_end}
{synopt:{opt notab:le}}suppress the summary table{p_end}

{syntab:Series and graphs}
{synopt:{opt gen:erate(stub)}}save the fifteen fitted series as
{it:stub}{cmd:_}{it:name}{p_end}
{synopt:{opt replace}}overwrite existing {cmd:generate()} variables{p_end}
{synopt:{opt gr:aph}}draw the three-panel impact figure{p_end}
{synopt:{opt metr:ics(string)}}which panels to draw: any combination of
{cmd:original}, {cmd:pointwise}, {cmd:cumulative}{p_end}
{synopt:{opt coefplot}}draw the posterior inclusion-probability plot{p_end}
{synopt:{opt leg:end}}add a legend to the top panel (the R plot has none){p_end}
{synopt:{opt name(string)}}stem for the graph names{p_end}
{synopt:{opt sav:ing(filename)}}save the combined graph to disk{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:causalimpact} estimates the causal effect of a designed intervention on a
time series, using the Bayesian structural time-series (BSTS) approach of
Brodersen, Gallusser, Koehler, Remy and Scott (2015). It is a faithful Stata
implementation of the R package {cmd:CausalImpact} 1.4.1
({browse "https://github.com/google/CausalImpact":github.com/google/CausalImpact}),
against which it has been verified on shared data; see
{helpb causalimpact_rcheck:help causalimpact rcheck}.

{pstd}
The idea is a generalisation of difference-in-differences to the time-series
setting. A state-space model is fitted to the response over the
{bf:pre-intervention period} only, using a set of {bf:control series} that were
not themselves affected by the intervention. The fitted model is then used to
predict what the response {it:would have been} over the post-intervention
period had the intervention not taken place. That prediction is the
{bf:counterfactual}; the difference between the observed response and the
counterfactual is the {bf:causal effect}.

{pstd}
Three features distinguish the method from a static regression or a classical
synthetic control:

{phang2}
1. The counterfactual is a full posterior predictive {it:trajectory}, not a
collection of pointwise predictions, so cumulative effects and their intervals
are coherent.

{phang2}
2. A spike-and-slab prior over the regression coefficients integrates out both
which controls to use and how strongly they matter, so the analyst does not have
to commit to a subset. Controls may enter with any sign and any scale, unlike
the convex weights of Abadie-type synthetic control.

{phang2}
3. Local level and seasonal components absorb the time-series structure the
controls do not explain, so serial correlation does not shrink the intervals
artificially.

{pstd}
The documentation is spread over five linked pages:

{p2colset 8 44 46 2}{...}
{p2col :{helpb causalimpact:help causalimpact}}this page: syntax, options,
stored results{p_end}
{p2col :{helpb causalimpact_methods:help causalimpact methods}}the model
equation by equation, the step-to-equation map, and the documented deviations
from the paper and from R{p_end}
{p2col :{helpb causalimpact_interpretation:help causalimpact interpretation}}a
detailed guide to reading the tables, the verbal report and the figure, with a
worked reading and the common misreadings{p_end}
{p2col :{helpb causalimpact_rcheck:help causalimpact rcheck}}the verification
against R {cmd:CausalImpact} 1.4.1, and how to re-run it{p_end}
{p2col :{helpb causalimpact_postestimation:help causalimpact postestimation}}{cmd:predict},
replay, and working with {cmd:e()}{p_end}
{p2colreset}{...}


{marker options}{...}
{title:Options}

{dlgtab:Periods}

{phang}
{opth preperiod(numlist)} specifies the first and last time point of the
pre-intervention period. This is the training period: the relationship between
the response and the controls is learned here. It must span at least three time
points. Boundaries are given in the units of the {helpb tsset} time variable, so
with daily data use, for example,
{cmd:pre(}{cmd:`}{cmd:=td(01jan2014)'} {cmd:`}{cmd:=td(11mar2014)')}. If the
response is missing at the start of the sample, the pre-period is silently moved
forward to the first non-missing observation, exactly as the R package does.

{phang}
{opth postperiod(numlist)} specifies the first and last time point of the
post-intervention period. It must start strictly after the pre-period ends; a
gap between the two periods is allowed and is treated as neither training nor
evaluation data. All summary statistics refer to this period only.

{dlgtab:MCMC}

{phang}
{opt niter(#)} sets the number of Gibbs draws. More draws give more accurate
posterior summaries. The default of 1000 matches the R package. Fewer than 1000
produces a warning; fewer than 10 is an error.

{phang}
{opt burnin(#)} sets how many initial draws to discard. The default,
{cmd:0.1*niter()}, reproduces {cmd:SuggestBurn(0.1, .)} in the R package, so
{cmd:niter(1000)} retains 900 draws.

{phang}
{opt seed(#)} makes the analysis reproducible. Note that the R package hard-codes
{cmd:seed = 1} inside its {cmd:bsts()} calls; here the seed is yours to choose,
and results will differ across seeds by Monte Carlo error.

{dlgtab:State model}

{phang}
{opt priorlevelsd(#)} is the prior standard deviation of the random walk that
drives the local level, expressed in units of the standard deviation of the
response. The default of 0.01 suits well-behaved, stable series with little
residual volatility once the controls have been regressed out. If the
counterfactual looks implausibly rigid, or if the series is volatile, 0.1 is the
safer choice, as validated on synthetic data in the R package documentation. Be
aware that this is the single most consequential prior in the model: it governs
how much of the post-period drift the counterfactual is allowed to track.

{phang}
{opt nseasons(#)} adds a seasonal component with the stated period. For daily
data, {cmd:nseasons(7)} gives a day-of-week effect. Only one seasonal component
is supported, as in the R package. {cmd:nseasons(1)} (the default) means none.

{phang}
{opt seasonduration(#)} is the number of consecutive time points that share a
season. Use {cmd:nseasons(7) seasonduration(1)} for a day-of-week effect on daily
data, and {cmd:nseasons(7) seasonduration(24)} for a day-of-week effect on hourly
data.

{phang}
{opt dynamicregression} lets each regression coefficient follow its own random
walk, eq. (2.6), instead of being constant. Use it when the relationship between
the controls and the treated series is believed to drift. Combined with a
flexible local level this easily over-specifies the model, so a static regression
is usually safer; see {helpb causalimpact_methods:help causalimpact methods} for
what changes in the prior.

{phang}
{opt nostandardize} turns off the pre-analysis standardisation. By default every
column is centred and scaled using its {it:pre-period} mean and standard
deviation, which makes the results invariant to linear rescaling of the data and
amounts to an empirical-Bayes choice of prior scale. Predictions are converted
back to the original units before any cumulative sum is taken.

{phang}
{opt noconstant} drops the intercept from the regression design matrix. By
default an intercept is included, as {cmd:bsts()} does. It is largely redundant
with the local level and, when the data are standardised, is close to zero.

{dlgtab:Spike-and-slab prior}

{phang}
{opt modelsize(#)} sets the expected number of covariates, {it:M}. Each covariate
receives prior inclusion probability {it:pi_j} = min(1, {it:M}/{it:J}) in
eq. (2.9). Framing the prior in terms of expected model size lets the model
absorb more and more candidate controls without switching to a hierarchical
prior.

{phang}
{opt r2(#)} and {opt priordf(#)} set the prior on the residual variance through
{it:s_eps} = {it:nu_eps}(1 - R{c 94}2)s{c 94}2_y in eq. (2.11). The defaults 0.8
and 50 are the values used for the empirical analyses of the paper.

{phang}
{opt ginfo(#)} and {opt dshrinkage(#)} control the Zellner g-prior of eq. (2.12),
Omega{c 94}-1 = (g/n){c -(}(1-d)X'X + d diag(X'X){c )-}. See
{helpb causalimpact_methods:help causalimpact methods} for why the default g is
0.01 rather than the 1 stated in the paper.

{phang}
{opt maxflips(#)} restricts each sweep to a random subset of inclusion indicators.
With very many controls (thousands) this speeds the sampler up considerably at
the cost of slower mixing.

{phang}
{opt sigmaupper(#)} truncates the residual standard deviation from above, in
units of the data standard deviation. It is off by default.

{dlgtab:Reporting, series and graphs}

{phang}
{opt level(#)} and {opt alpha(#)} are two ways of asking for the same thing:
{cmd:level(90)} is identical to {cmd:alpha(0.10)}. The Stata spelling wins if
both are given.

{phang}
{opt report} prints the verbal interpretation of the results, a port of the R
package's {cmd:summary(impact, "report")}. It can also be requested after
estimation by replaying with {cmd:causalimpact, report}.

{phang}
{opt generate(stub)} creates fifteen new double variables holding the complete
set of fitted series, mirroring {cmd:impact$series} in R:

{p2colset 12 40 42 2}{...}
{p2col :{it:stub}{cmd:_response}}observed response{p_end}
{p2col :{it:stub}{cmd:_cum_response}}cumulative observed response{p_end}
{p2col :{it:stub}{cmd:_pred}}counterfactual, posterior mean{p_end}
{p2col :{it:stub}{cmd:_lower} {it:stub}{cmd:_upper}}counterfactual credible band{p_end}
{p2col :{it:stub}{cmd:_cum_pred}}cumulative counterfactual{p_end}
{p2col :{it:stub}{cmd:_cum_lower} {it:stub}{cmd:_cum_upper}}its credible band{p_end}
{p2col :{it:stub}{cmd:_effect}}pointwise causal effect, eq. (2.15){p_end}
{p2col :{it:stub}{cmd:_effect_lower} {it:stub}{cmd:_effect_upper}}its credible band{p_end}
{p2col :{it:stub}{cmd:_cum_effect}}cumulative causal effect, eq. (2.16){p_end}
{p2col :{it:stub}{cmd:_cum_effect_lower} {it:stub}{cmd:_cum_effect_upper}}its band{p_end}
{p2col :{it:stub}{cmd:_avg_effect}}running-average effect, eq. (2.17){p_end}
{p2colreset}{...}

{phang}
{opt graph} draws the three-panel figure of Figure 1 and Figures 5-7 of the
paper: the observed series with its counterfactual and credible band; the
pointwise effect; and the cumulative effect. Each panel is also left in memory
under its own name so that panels can be re-combined or restyled.

{phang2}
The styling reproduces the R package's {cmd:ggplot2} figure: the credible band
is {cmd:slategray2} (RGB 185 211 238), the counterfactual is a {cmd:darkblue}
(RGB 0 0 139) dashed line, the observed series is a solid black line, and the
panel uses the {cmd:theme_bw} look, i.e. a white plot region with a thin
grey20 border and pale grey92 gridlines. Period boundaries are dashed grey
vertical lines and the zero line in the lower two panels is solid grey. Panel
labels sit in a boxed strip on the right, as {cmd:facet_grid(metric ~ .)}
produces in R. As in R there are no axis titles and no legend.

{phang}
{opt legend} adds a legend under the top panel identifying the observed series,
the counterfactual and the credible band. The R figure has none, so this is
off by default; turn it on when the figure has to stand alone in a paper.

{phang}
{opt metrics(string)} selects panels, for example
{cmd:metrics(original pointwise)}. Drop {cmd:cumulative} whenever the response
is a {it:stock} rather than a {it:flow} quantity: summing subscribers or prices
across time is not meaningful, whereas summing clicks or sales is (paper,
Sec. 2.4).

{phang}
{opt coefplot} draws posterior inclusion probabilities for the regression
component, the counterpart of {cmd:plot(bsts.model, "coefficients")} in R.
Covariates are ordered with the largest inclusion probability at the top, and
each bar is shaded by the probability that its coefficient is positive given
that it is in the model. R encodes this on a white-to-black ramp; here the same
information runs along a blue ramp from pale blue (negative) to the same
{cmd:darkblue} used for the counterfactual line (positive), so the two figures
share one palette.


{marker output}{...}
{title:Interpreting the output}

{pstd}
The header reports the response, the controls, the state components in use, the
periods, and the MCMC bookkeeping. The main table has two columns.

{phang}
{bf:Average} summarises the post-period one time point at a time: the mean
observed value, the mean counterfactual, and the mean effect.

{phang}
{bf:Cumulative} sums over the post-period. This is the column to read when the
response is a flow quantity (clicks, sales, sign-ups) and the question is "how
many extra units did the intervention produce". It is meaningless for a stock
quantity.

{pstd}
The rows are:

{phang2}
{bf:Actual} - what was observed.

{phang2}
{bf:Prediction} - the counterfactual, i.e. what the model expects would have
happened without the intervention, with its posterior standard deviation and
credible interval.

{phang2}
{bf:Absolute effect} - Actual minus Prediction, with its own posterior standard
deviation and interval. Note that this interval is computed from the posterior
draws of the difference, not by differencing the two intervals above.

{phang2}
{bf:Relative effect} - the same thing as a percentage of the counterfactual.
The Average and Cumulative entries are deliberately identical: both report the
posterior of sum(y)/sum(counterfactual) - 1, exactly as in the R package.

{pstd}
Two probabilities close the table.
{bf:p} is the one-sided Bayesian tail-area probability of the cumulative effect:
the posterior probability of having drawn a counterfactual sum at least as
extreme as the observed sum. {bf:Posterior probability of an effect} is 1 - p.
Checking whether the credible interval excludes zero is a two-sided test;
checking whether p is below alpha is a one-sided test, so the two can disagree in
borderline cases.

{pstd}
When controls are present, a second table reports, for each of them, the
posterior inclusion probability, the model-averaged posterior mean and standard
deviation of its coefficient, and the probability that the coefficient is
positive given that it is in the model. Coefficients are reported in the metric
the model is fitted in, that is, standardised unless {cmd:nostandardize} was
specified. This matches the R package, which likewise never converts them back.

{pstd}
Because the intercept is redundant with the local level, do not read it as a
structural quantity.


{marker remarks}{...}
{title:Remarks and practical guidance}

{dlgtab:The assumptions that actually matter}

{pstd}
As with every non-experimental approach to causal inference, valid conclusions
require strong assumptions. Two of them do the real work:

{phang2}
{bf:The controls must not themselves have been affected by the intervention.}
If an advertising campaign in the United States spills over into Canada, and
Canada is used as a control, the counterfactual is contaminated and the effect
is understated. Plot every control and reason about the spillover explicitly.

{phang2}
{bf:The relationship between controls and response, learned in the pre-period,
must remain stable through the post-period.} Section 3 of the paper shows what
happens when it does not: a structural break in the post-period destroys the
orderly decay of estimation accuracy. {cmd:dynamicregression} relaxes this
somewhat, at the cost of a much more flexible model.

{dlgtab:Checking the assumptions}

{pstd}
The single most useful diagnostic is a {bf:placebo analysis}: pick a date in the
pre-period where nothing happened, declare it an intervention, and re-run. You
should find no significant effect. If you do find one, the model is
mis-specified or the controls are inadequate, and the headline result should not
be trusted. Section 7 of the accompanying self-test do-file does exactly this.

{pstd}
Also check the pre-period fit visually in panel A: the counterfactual should
track the observed series closely before the intervention. In the paper's
Figure 5 it even reproduces a spike two weeks before the campaign.

{dlgtab:How long a post-period?}

{pstd}
Posterior intervals widen as the forecast horizon grows, which is a feature, not
a defect: predicting further into the retrospective future is genuinely more
uncertain. But an over-long post-period dilutes a real effect that has already
worn off, and the cumulative interval can drift back across zero. The paper's
Figure 1(c) shows a real effect losing significance about five months after the
intervention purely because of this.

{dlgtab:Flow versus stock}

{pstd}
Report the cumulative effect only for flow quantities. For stock quantities use
the running average, eq. (2.17), available as
{it:stub}{cmd:_avg_effect} through {cmd:generate()}, and drop the cumulative
panel with {cmd:metrics(original pointwise)}.

{dlgtab:Sample size, controls, and run time}

{pstd}
Aim for a pre-period long enough to pin down the relationship, and prefer many
candidate controls to few: the spike-and-slab prior is designed to choose among
them, and adding an irrelevant control costs little. Controls that are close in
nature to the treated series (the same product elsewhere, industry-wide search
volume) are the most informative.

{pstd}
Run time is roughly linear in {cmd:niter()} times the number of time points, and
quadratic in the state dimension, which is 1 + {cmd:nseasons()} - 1. With very
many controls, {cmd:maxflips()} is the lever to pull.

{dlgtab:Missing values}

{pstd}
The response may contain missing values in the pre-period; the Kalman filter
simply skips the update step. The controls may not, since they are needed at
every time point to form the counterfactual. Impute them, or drop the control.

{dlgtab:Gaps in the time variable}

{pstd}
Like the R package, {cmd:causalimpact} models the data in row order and ignores
gaps in the {helpb tsset} time variable; a note is printed when gaps are found.
This is harmless without a seasonal component but mis-aligns one if present.
{helpb tsfill} first if you are using {cmd:nseasons()}.


{marker rcompat}{...}
{title:Compatibility with the R package}

{pstd}
The model, the priors, the sampler and every reported statistic follow R
{cmd:CausalImpact} 1.4.1. Point estimates, intervals and the tail-area
probability agree with the R output up to Monte Carlo error; they cannot agree
bit for bit, because the two implementations draw from different random-number
streams. Quantiles use R's default type-7 definition so that the interval
endpoints are computed identically given the same draws.

{pstd}
Three deliberate, documented differences are described in full in
{helpb causalimpact_methods:help causalimpact methods}: the treatment of the
Zellner g default, the residual-variance prior in the no-covariate case, and the
prior on the dynamic-regression innovation variances. None affects the default
static-regression analysis that the paper's empirical sections use.


{marker examples}{...}
{title:Examples}

{pstd}Set up the toy dataset of the R vignette: a response {cmd:y}, one control
{cmd:x1}, and a lift of 10 units from time 71.{p_end}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 1}{p_end}
{phang2}{cmd:. set obs 100}{p_end}
{phang2}{cmd:. gen int t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen double x1 = 0}{p_end}
{phang2}{cmd:. replace x1 = 0.999*x1[_n-1] + rnormal() in 2/l}{p_end}
{phang2}{cmd:. replace x1 = x1 + 100}{p_end}
{phang2}{cmd:. gen double y = 1.2*x1 + rnormal()}{p_end}
{phang2}{cmd:. replace y = y + 10 if t >= 71}{p_end}

{pstd}The basic analysis:{p_end}
{phang2}{cmd:. causalimpact y x1, pre(1 70) post(71 100)}{p_end}

{pstd}With the figure and the verbal report:{p_end}
{phang2}{cmd:. causalimpact y x1, pre(1 70) post(71 100) graph report}{p_end}

{pstd}Dated data; the periods are given as dates:{p_end}
{phang2}{cmd:. causalimpact y x1, pre(`}{cmd:=td(01jan2014)' `}{cmd:=td(11mar2014)') post(`}{cmd:=td(12mar2014)' `}{cmd:=td(10apr2014)')}{p_end}

{pstd}Many candidate controls, letting the spike-and-slab prior choose:{p_end}
{phang2}{cmd:. causalimpact y x1-x50, pre(1 200) post(201 260) modelsize(5) coefplot}{p_end}

{pstd}Daily data with a day-of-week effect and 90% intervals:{p_end}
{phang2}{cmd:. causalimpact y x1 x2, pre(1 300) post(301 400) nseasons(7) level(90)}{p_end}

{pstd}Time-varying coefficients, more draws, and a looser level prior:{p_end}
{phang2}{cmd:. causalimpact y z1 z2, pre(1 365) post(366 546) dynamicregression niter(5000) priorlevelsd(0.1)}{p_end}

{pstd}Keep the series and plot only what makes sense for a stock quantity:{p_end}
{phang2}{cmd:. causalimpact y x1, pre(1 70) post(71 100) generate(ci) metrics(original pointwise)}{p_end}
{phang2}{cmd:. list t ci_pred ci_effect ci_avg_effect if t >= 71}{p_end}

{pstd}A placebo check on a date where nothing happened:{p_end}
{phang2}{cmd:. causalimpact y x1, pre(1 40) post(41 70) report}{p_end}

{pstd}The complete, self-checking demonstration:{p_end}
{phang2}{cmd:. do causalimpact_example.do}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:causalimpact} is an {cmd:eclass} command. It stores:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations in the estimation sample{p_end}
{synopt:{cmd:e(N_pre)}}observations in the pre-period{p_end}
{synopt:{cmd:e(N_post)}}observations in the post-period{p_end}
{synopt:{cmd:e(N_model)}}observations in the modelling window{p_end}
{synopt:{cmd:e(niter)}}MCMC draws requested{p_end}
{synopt:{cmd:e(burnin)}}draws discarded{p_end}
{synopt:{cmd:e(ndraws)}}draws retained{p_end}
{synopt:{cmd:e(alpha)}}tail-area probability{p_end}
{synopt:{cmd:e(level)}}credible-interval level{p_end}
{synopt:{cmd:e(p)}}one-sided Bayesian tail-area probability{p_end}
{synopt:{cmd:e(prob_effect)}}posterior probability of an effect, 1 - p{p_end}
{synopt:{cmd:e(actual_avg)}, {cmd:e(actual_cum)}}observed average and sum{p_end}
{synopt:{cmd:e(pred_avg)}, {cmd:e(pred_cum)}}counterfactual average and sum{p_end}
{synopt:{cmd:e(abseffect)}, {cmd:e(abseffect_sd)}}average absolute effect and its s.d.{p_end}
{synopt:{cmd:e(abseffect_cum)}, {cmd:e(abseffect_cum_sd)}}cumulative absolute effect and its s.d.{p_end}
{synopt:{cmd:e(releffect)}, {cmd:e(releffect_sd)}}relative effect and its s.d.{p_end}
{synopt:{cmd:e(sigma_obs)}}posterior mean observation standard deviation{p_end}
{synopt:{cmd:e(sigma_level)}}posterior mean local-level standard deviation{p_end}
{synopt:{cmd:e(sigma_seas)}}posterior mean seasonal standard deviation, if any{p_end}
{synopt:{cmd:e(k_covariates)}}number of controls supplied{p_end}
{synopt:{cmd:e(priorlevelsd)}, {cmd:e(nseasons)}, {cmd:e(seasonduration)}}model settings{p_end}
{synopt:{cmd:e(modelsize)}, {cmd:e(r2)}, {cmd:e(priordf)}, {cmd:e(ginfo)}, {cmd:e(dshrinkage)}, {cmd:e(maxflips)}}prior settings{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:causalimpact}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of the response{p_end}
{synopt:{cmd:e(covariates)}}names of the controls{p_end}
{synopt:{cmd:e(timevar)}}{help tsset} time variable{p_end}
{synopt:{cmd:e(pre_period)}, {cmd:e(post_period)}}period boundaries{p_end}
{synopt:{cmd:e(model)}}state components used{p_end}
{synopt:{cmd:e(regression)}}regression type{p_end}
{synopt:{cmd:e(standardize)}}whether the data were standardised{p_end}
{synopt:{cmd:e(predict)}}{cmd:causalimpact_p}{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}model-averaged posterior mean coefficients{p_end}
{synopt:{cmd:e(V)}}posterior variance matrix of the coefficients{p_end}
{synopt:{cmd:e(summary)}}2 x 15 summary table; rows {cmd:Average} and
{cmd:Cumulative}, columns {cmd:Actual}, {cmd:Pred}, {cmd:Pred_lower},
{cmd:Pred_upper}, {cmd:Pred_sd}, {cmd:AbsEffect}, {cmd:AbsEffect_lower},
{cmd:AbsEffect_upper}, {cmd:AbsEffect_sd}, {cmd:RelEffect},
{cmd:RelEffect_lower}, {cmd:RelEffect_upper}, {cmd:RelEffect_sd},
{cmd:alpha}, {cmd:p}. This is exactly {cmd:impact$summary} in R.{p_end}
{synopt:{cmd:e(inclusion)}}{it:J} x 4 matrix of posterior inclusion probability,
posterior mean, posterior s.d. and P(coefficient > 0 | included){p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Brodersen, K. H., F. Gallusser, J. Koehler, N. Remy, and S. L. Scott. 2015.
Inferring causal impact using Bayesian structural time-series models.
{it:Annals of Applied Statistics} 9(1): 247-274.
{browse "https://doi.org/10.1214/14-AOAS788":DOI: 10.1214/14-AOAS788}. Open
access from the Institute of Mathematical Statistics.

{phang}
Abadie, A., A. Diamond, and J. Hainmueller. 2010. Synthetic control methods for
comparative case studies: estimating the effect of California's tobacco control
program. {it:Journal of the American Statistical Association} 105: 493-505.

{phang}
Durbin, J., and S. J. Koopman. 2002. A simple and efficient simulation smoother
for state space time series analysis. {it:Biometrika} 89: 603-615.

{phang}
George, E. I., and R. E. McCulloch. 1997. Approaches for Bayesian variable
selection. {it:Statistica Sinica} 7: 339-374.

{phang}
Scott, S. L., and H. R. Varian. 2014. Predicting the present with Bayesian
structural time series. {it:International Journal of Mathematical Modeling and
Optimization} 5: 4-23.

{phang}
Zellner, A. 1986. On assessing prior distributions and Bayesian regression
analysis with g-prior distributions. In {it:Bayesian Inference and Decision
Techniques}, 233-243. Amsterdam: North-Holland.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
https://github.com/merwanroudane


{title:Also see}

{psee}
Help:  {helpb causalimpact_methods:causalimpact methods},
{helpb causalimpact_interpretation:causalimpact interpretation},
{helpb causalimpact_rcheck:causalimpact rcheck},
{helpb causalimpact_postestimation:causalimpact postestimation}
{p_end}
