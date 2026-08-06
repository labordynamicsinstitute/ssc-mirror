{smcl}
{* *! version 1.0.0  05aug2026}{...}
{vieweralsosee "causalimpact" "help causalimpact"}{...}
{vieweralsosee "causalimpact methods" "help causalimpact_methods"}{...}
{vieweralsosee "causalimpact interpretation" "help causalimpact_interpretation"}{...}
{vieweralsosee "causalimpact rcheck" "help causalimpact_rcheck"}{...}
{viewerjumpto "Postestimation commands" "causalimpact_postestimation##commands"}{...}
{viewerjumpto "Syntax for predict" "causalimpact_postestimation##predict"}{...}
{viewerjumpto "Options for predict" "causalimpact_postestimation##options"}{...}
{viewerjumpto "Replay and report" "causalimpact_postestimation##replay"}{...}
{viewerjumpto "Working with e()" "causalimpact_postestimation##ereturn"}{...}
{viewerjumpto "Remarks" "causalimpact_postestimation##remarks"}{...}
{viewerjumpto "Examples" "causalimpact_postestimation##examples"}{...}
{viewerjumpto "Author" "causalimpact_postestimation##author"}{...}

{title:Title}

{phang}
{bf:causalimpact postestimation} {hline 2} Postestimation tools for
{helpb causalimpact}


{marker commands}{...}
{title:Postestimation commands}

{pstd}
The following commands are available after {cmd:causalimpact}:

{synoptset 22 tabbed}{...}
{synopthdr:command}
{synoptline}
{synopt :{helpb causalimpact_postestimation##predict:predict}}counterfactual,
effects and their credible bands{p_end}
{synopt :{cmd:causalimpact}}replay the summary table{p_end}
{synopt :{cmd:causalimpact, report}}print the verbal interpretation{p_end}
{synopt :{helpb estimates}}cataloguing estimation results{p_end}
{synopt :{helpb lincom}}point estimates and tests of linear combinations of the
regression coefficients{p_end}
{synopt :{helpb test}}Wald tests on the regression coefficients{p_end}
{synoptline}


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 24 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{syntab:Counterfactual}
{synopt :{opt count:erfactual}}counterfactual, posterior mean; the default{p_end}
{synopt :{opt low:er}}lower bound of its credible band{p_end}
{synopt :{opt upp:er}}upper bound of its credible band{p_end}
{synopt :{opt cumc:ounterfactual}}cumulative counterfactual{p_end}
{synopt :{opt cuml:ower}}its lower bound{p_end}
{synopt :{opt cumu:pper}}its upper bound{p_end}

{syntab:Causal effect}
{synopt :{opt eff:ect}}pointwise causal effect, eq. (2.15){p_end}
{synopt :{opt effl:ower}}its lower bound{p_end}
{synopt :{opt effu:pper}}its upper bound{p_end}
{synopt :{opt cume:ffect}}cumulative causal effect, eq. (2.16){p_end}
{synopt :{opt cumeffl:ower}}its lower bound{p_end}
{synopt :{opt cumeffu:pper}}its upper bound{p_end}
{synopt :{opt avge:ffect}}running-average causal effect, eq. (2.17){p_end}

{syntab:Data}
{synopt :{opt resp:onse}}observed response, as used by the model{p_end}
{synopt :{opt cumr:esponse}}cumulative observed response{p_end}
{synopt :{opt xb}}regression (synthetic-control) component only{p_end}
{synoptline}


{marker options}{...}
{title:Options for predict}

{phang}
{opt counterfactual}, the default, stores the posterior mean of the
counterfactual: what the model expects the response would have been in the
absence of the intervention. It is defined over the whole modelling window, so it
also covers the pre-period, where it is the fitted value and can be used to judge
how well the model tracks the data before anything happened.

{phang}
{opt lower} and {opt upper} give the central credible band of the counterfactual
at the level used at estimation. These are quantiles of the posterior predictive
draws of the {it:response}, so they include observation noise; the point
prediction is the mean of the noise-free state, which is why the point prediction
is not the midpoint of the band in general.

{phang}
{opt effect}, {opt efflower} and {opt effupper} give the pointwise causal effect
and its band. They are missing outside the pre- and post-periods.

{phang}
{opt cumeffect}, {opt cumefflower} and {opt cumeffupper} give the cumulative
effect. It is exactly zero throughout the pre-period by construction; see
{helpb causalimpact_methods:help causalimpact methods}.

{phang}
{opt avgeffect} gives the running average of the pointwise effect over the
post-period, eq. (2.17). Use it in place of the cumulative effect whenever the
response is a stock quantity that cannot meaningfully be summed across time.

{phang}
{opt xb} computes the regression component alone, using {cmd:e(b)}. It requires
the model to have had covariates. Note that the coefficients are in the metric
the model was fitted in, so unless {cmd:nostandardize} was used, {cmd:xb} is on
the standardised scale and is a diagnostic, not a prediction of the response.


{marker replay}{...}
{title:Replay and report}

{pstd}
Typing {cmd:causalimpact} with no arguments redisplays the summary table.
Typing

{phang2}{cmd:. causalimpact, report}{p_end}

{pstd}
prints the verbal interpretation of the results: a paragraph-by-paragraph
account of the average effect, the cumulative effect, the relative effect, and
whether the finding is significant, with the standard caveats about model
assumptions. This is a port of {cmd:summary(impact, "report")} in the R package
and is intended to be pasted into a results section as a starting point.

{phang2}{cmd:. causalimpact, report digits(3)}{p_end}

{pstd}
controls the rounding used in that text.


{marker ereturn}{...}
{title:Working with e()}

{pstd}
The complete summary table is available as a matrix, with the same layout as
{cmd:impact$summary} in R:

{phang2}{cmd:. matrix S = e(summary)}{p_end}
{phang2}{cmd:. matrix list S, format(%9.4f)}{p_end}
{phang2}{cmd:. display "cumulative effect = " S[2,6]}{p_end}
{phang2}{cmd:. display "95% CI = [" S[2,7] ", " S[2,8] "]"}{p_end}

{pstd}
Rows are {cmd:Average} and {cmd:Cumulative}; the fifteen columns are
{cmd:Actual}, {cmd:Pred}, {cmd:Pred_lower}, {cmd:Pred_upper}, {cmd:Pred_sd},
{cmd:AbsEffect}, {cmd:AbsEffect_lower}, {cmd:AbsEffect_upper},
{cmd:AbsEffect_sd}, {cmd:RelEffect}, {cmd:RelEffect_lower},
{cmd:RelEffect_upper}, {cmd:RelEffect_sd}, {cmd:alpha}, {cmd:p}.

{pstd}
The posterior summary of the regression component is in {cmd:e(inclusion)}, with
one row per covariate and columns {cmd:P_include}, {cmd:PostMean},
{cmd:PostSD}, {cmd:P_positive}. To list the controls the model actually selected:

{phang2}{cmd:. matrix I = e(inclusion)}{p_end}
{phang2}{cmd:. local nm : rownames I}{p_end}
{phang2}{cmd:. forvalues j = 1/`}{cmd:=rowsof(I)' {c -(}}{p_end}
{phang2}{cmd:.     if I[`}{cmd:j',1] > 0.5 di "`}{cmd::word `}{cmd:j' of `}{cmd:nm''"}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}
Because {cmd:e(b)} and {cmd:e(V)} are posted, {helpb test} and {helpb lincom}
work on the regression coefficients. Bear in mind that these are posterior
moments of a model-averaged, spike-and-slab coefficient vector, not sampling
moments of a maximum-likelihood estimator: a coefficient whose posterior
inclusion probability is low will have a posterior mean shrunk toward zero and a
posterior variance dominated by the mass at exactly zero. Read
{cmd:e(inclusion)} before reading any Wald test.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:predict} reads the fitted series from memory rather than recomputing them,
which is why it is instant and why it reproduces {cmd:generate()} exactly. The
consequence is that the series do not survive {helpb discard}, {cmd:mata clear},
or re-loading the package; {cmd:predict} then stops with a clear message rather
than returning something wrong. If the series are needed permanently, ask for
them at estimation time:

{phang2}{cmd:. causalimpact y x1, pre(1 70) post(71 100) generate(ci)}{p_end}

{pstd}
which creates the same fifteen series as ordinary variables in one step, and
survives anything.

{pstd}
{cmd:predict} respects {cmd:if} and {cmd:in} and fills only the observations in
the estimation sample; everything else is left missing.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. causalimpact y x1, pre(1 70) post(71 100) niter(2000) seed(42)}{p_end}

{pstd}The counterfactual and its band:{p_end}
{phang2}{cmd:. predict cf, counterfactual}{p_end}
{phang2}{cmd:. predict cf_lo, lower}{p_end}
{phang2}{cmd:. predict cf_hi, upper}{p_end}

{pstd}The effects:{p_end}
{phang2}{cmd:. predict eff, effect}{p_end}
{phang2}{cmd:. predict ceff, cumeffect}{p_end}
{phang2}{cmd:. predict aeff, avgeffect}{p_end}

{pstd}A hand-built version of the top panel:{p_end}
{phang2}{cmd:. twoway (rarea cf_hi cf_lo t, color(gs14)) (line y t) (line cf t, lpattern(dash)), xline(70)}{p_end}

{pstd}How large was the effect in the first week after the intervention?{p_end}
{phang2}{cmd:. summarize eff if inrange(t, 71, 77)}{p_end}

{pstd}The verbal report and the underlying numbers:{p_end}
{phang2}{cmd:. causalimpact, report}{p_end}
{phang2}{cmd:. matrix list e(summary), format(%9.4f)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
https://github.com/merwanroudane


{title:Also see}

{psee}
Help:  {helpb causalimpact},
{helpb causalimpact_methods:causalimpact methods},
{helpb causalimpact_interpretation:causalimpact interpretation},
{helpb causalimpact_rcheck:causalimpact rcheck}
{p_end}
