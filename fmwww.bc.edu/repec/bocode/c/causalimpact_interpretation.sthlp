{smcl}
{* *! version 1.0.0  05aug2026}{...}
{vieweralsosee "causalimpact" "help causalimpact"}{...}
{vieweralsosee "causalimpact methods" "help causalimpact_methods"}{...}
{vieweralsosee "causalimpact rcheck" "help causalimpact_rcheck"}{...}
{vieweralsosee "causalimpact postestimation" "help causalimpact_postestimation"}{...}
{viewerjumpto "Reading the header" "causalimpact_interpretation##header"}{...}
{viewerjumpto "Average versus Cumulative" "causalimpact_interpretation##columns"}{...}
{viewerjumpto "Reading the main table" "causalimpact_interpretation##table"}{...}
{viewerjumpto "The two probabilities" "causalimpact_interpretation##pvalue"}{...}
{viewerjumpto "The inclusion table" "causalimpact_interpretation##inclusion"}{...}
{viewerjumpto "Reading the figure" "causalimpact_interpretation##figure"}{...}
{viewerjumpto "The verbal report" "causalimpact_interpretation##report"}{...}
{viewerjumpto "A worked reading" "causalimpact_interpretation##worked"}{...}
{viewerjumpto "Ten ways to misread this" "causalimpact_interpretation##traps"}{...}
{viewerjumpto "Checklist" "causalimpact_interpretation##checklist"}{...}
{viewerjumpto "Author" "causalimpact_interpretation##author"}{...}

{title:Title}

{phang}
{bf:causalimpact interpretation} {hline 2} How to read the tables, the report
and the figure


{marker header}{...}
{title:Reading the header}

{pstd}
Everything above the first double rule tells you what was fitted, not what was
found. Read it first: most bad causal-impact analyses are visible here rather
than in the numbers.

{p2colset 5 24 26 2}{...}
{p2col :{bf:Response}}the treated series.{p_end}
{p2col :{bf:Covariates}}the control series that build the synthetic control.
Truncated with "..." if long; the full list is in {cmd:e(covariates)}. If this
says {cmd:(none)}, the counterfactual is a pure extrapolation of the response's
own history and will be far less trustworthy.{p_end}
{p2col :{bf:State model}}which components are in the state: local level, and
optionally a seasonal block and a regression block.{p_end}
{p2col :{bf:Regression}}{cmd:static spike-and-slab}, {cmd:dynamic}, or
{cmd:none}.{p_end}
{p2col :{bf:Standardised}}whether columns were centred and scaled on pre-period
moments. Affects the metric of the coefficients, not the reported effects.{p_end}
{p2col :{bf:Pre-period / Post-period}}the training and evaluation windows, in
the units of the {help tsset} time variable.{p_end}
{p2col :{bf:Obs (pre)}}the single most important number in the header. This is
how much data the model had to learn the relationship. Twenty pre-period points
cannot support a confident counterfactual over sixty post-period points.{p_end}
{p2col :{bf:MCMC draws / Burn-in / Retained}}the sampler's bookkeeping.
Retained = draws - burn-in. With {cmd:niter(1000)} you retain 900.{p_end}
{p2colreset}{...}

{pstd}
Note the asymmetry between {bf:Obs (pre)} and {bf:Obs (post)}. Section 3 of the
paper shows estimation accuracy decaying steadily as the forecast horizon grows.
A post-period much longer than the pre-period is a warning sign, not a bonus.


{marker columns}{...}
{title:Average versus Cumulative -- pick one before you look}

{pstd}
The two columns answer different questions and only one is usually right for
your data.

{phang}
{bf:Average} is the mean over the post-period, time point by time point. "On a
typical day during the campaign, how much higher was the response?" This is
always interpretable.

{phang}
{bf:Cumulative} is the sum over the post-period. "How many extra units in total
did the intervention produce?" This is interpretable {bf:only for flow
quantities} -- clicks, sales, sign-ups, visits, revenue -- things that accumulate.

{pstd}
For a {bf:stock} quantity -- number of current subscribers, a price, a stock
level, a temperature, an unemployment rate -- summing across time is
meaningless. Adding today's subscriber count to yesterday's does not produce a
quantity that exists. In that case:

{phang2}
o Report the {bf:Average} column and ignore the Cumulative one.{p_end}
{phang2}
o Drop the third panel with {cmd:metrics(original pointwise)}.{p_end}
{phang2}
o If you want a cumulative-style summary, use the {bf:running average} of
eq. (2.17), available as {it:stub}{cmd:_avg_effect} from {cmd:generate()}. It
stays interpretable for stocks and flows alike.{p_end}

{pstd}
This distinction is from Sec. 2.4 of the paper and it is the single most common
misuse of the method in applied work.


{marker table}{...}
{title:Reading the main table}

{pstd}
Four blocks, each with a point estimate, a posterior standard deviation, and a
credible interval.

{phang}
{bf:Actual} -- what was observed in the post-period. No uncertainty: it is data.

{phang}
{bf:Prediction} -- the counterfactual. What the model says would have happened
without the intervention. Its interval reflects genuine uncertainty about an
unobservable quantity, which is why it is usually wider than people expect.

{phang}
{bf:Absolute effect} -- Actual minus Prediction, in the units of the response.
This is the headline number.

{phang}
{bf:Relative effect} -- the same thing as a percentage of the counterfactual.

{pstd}
Three things about these numbers routinely confuse people.

{phang2}
{bf:1. The effect interval is not the difference of the two intervals above it.}
It is computed from the posterior draws of the {it:difference}, which is
narrower than differencing the endpoints would suggest, because the observed
value carries no uncertainty. Do not try to reconcile them by hand.

{phang2}
{bf:2. The point prediction is not the midpoint of its own interval.} The point
estimate is the mean of the noise-free state; the interval comes from quantiles
of draws that include observation noise. The gap is deliberate and matches the R
package.

{phang2}
{bf:3. Relative effect Average and Cumulative are identical by construction.}
Both report the posterior of sum(y)/sum(counterfactual) - 1. This is not a bug
and not a display quirk; the R package does the same. There is only one relative
effect.

{pstd}
Also note that the relative effect is generally {bf:not} the absolute effect
divided by the prediction. Posterior distributions of ratios are not symmetric,
so E[y/c] does not equal E[y]/E[c]. When the gap exceeds five percentage points
the verbal report says so explicitly.


{marker pvalue}{...}
{title:The two probabilities, and why they can disagree}

{pstd}
The table closes with

{p2colset 5 42 44 2}{...}
{p2col :{bf:Posterior tail-area probability p}}the one-sided Bayesian tail-area
probability of the {it:cumulative} effect{p_end}
{p2col :{bf:Posterior probability of an effect}}1 - p{p_end}
{p2colreset}{...}

{pstd}
p is computed by counting how many posterior draws of the counterfactual sum
are at least as extreme as the observed sum, taking the smaller tail, and
dividing by the number of draws plus one. It is a {bf:one-sided} statement.

{pstd}
Checking whether the credible interval excludes zero is a {bf:two-sided} test.
So in borderline cases the star next to p and the interval can disagree. That is
expected, not an inconsistency. The significance stars in this table follow p;
the single star {cmd:*} marks the case where the interval excludes zero but p is
above 0.05.

{pstd}
One hard limit worth knowing: p can never be smaller than 1/(retained draws + 1).
With {cmd:niter(1000)} the floor is 1/901 = 0.00111. If you see exactly that
value, it means "as small as this sampler can report", not "0.00111 precisely".
Raise {cmd:niter()} if you need finer resolution in the tail.


{marker inclusion}{...}
{title:The inclusion table}

{pstd}
When controls are present, a second table reports the spike-and-slab posterior
for each of them.

{p2colset 5 22 24 2}{...}
{p2col :{bf:P(incl)}}posterior probability that the covariate is in the model.
Above ~0.5 the model is relying on it; near 0 it has been discarded.{p_end}
{p2col :{bf:Post. mean}}model-averaged posterior mean of the coefficient. Draws
that exclude the covariate contribute exactly zero, so a covariate with
P(incl) = 0.02 will have a mean shrunk almost to zero regardless of how large
its coefficient is when it does enter.{p_end}
{p2col :{bf:Post. s.d.}}model-averaged posterior standard deviation, on the same
mixed scale.{p_end}
{p2col :{bf:P(b>0)}}probability the coefficient is positive {it:given that it is
in the model}. Conditional, not marginal. For a covariate that is almost never
included this is computed from a handful of draws and is close to noise --
values like 0.000, 0.500 or 1.000 on a covariate with P(incl) = 0.003 mean
nothing.{p_end}
{p2colreset}{...}

{pstd}
Read P(incl) first and only then look at the other three columns. A coefficient
summary is meaningful only for covariates the model actually uses.

{pstd}
Two structural points. First, coefficients are in the metric the model is fitted
in -- standardised unless {cmd:nostandardize} was used -- exactly as in the R
package, which likewise never converts them back. Second, {cmd:_cons} is
redundant with the local level and should not be read as a structural intercept.

{pstd}
A special case that surprises people: with few candidate controls, the prior
inclusion probability is min(1, {cmd:modelsize()}/J). With one covariate plus an
intercept and the default {cmd:modelsize(3)}, that is min(1, 3/2) = 1, so
{bf:everything is forced into the model} and every P(incl) prints as 1.000.
That is the prior speaking, not evidence. Variable selection only does visible
work when you have more candidates than {cmd:modelsize()}.


{marker figure}{...}
{title:Reading the figure}

{pstd}
{bf:Panel A, original.} Observed series in solid black, counterfactual as a
dashed dark blue line, credible band shaded. {bf:Look at the pre-period first.}
The counterfactual should track the observed series closely there -- that stretch
is the model's audition. If it fits badly before the intervention, nothing after
it is trustworthy. In Figure 5 of the paper the fit is good enough to reproduce
a spike two weeks before the campaign.

{pstd}
{bf:Panel B, pointwise.} The gap between observation and counterfactual, period
by period, with its band. This is where you see the {it:shape} of the effect:
when it started, whether it peaked, whether it decayed. A band that includes zero
at a given time point means no detectable effect at that point, even if the
overall effect is significant.

{pstd}
{bf:Panel C, cumulative.} The running total of panel B. It should be a flat zero
line through the whole pre-period -- that is guaranteed by construction, and if it
is not, something is wrong. A steadily rising line with a band clear of zero is
a sustained effect. A line that flattens means the effect has worn off; the band
crossing back over zero means the cumulative effect is no longer significant,
which is exactly what Figure 1(c) of the paper illustrates.

{pstd}
The dashed vertical lines mark the end of the pre-period and the end of the
post-period. The band widens as you move right in every panel. That is not a
defect -- predicting further into the counterfactual future is genuinely more
uncertain, and a model whose band did not widen would be lying to you.


{marker report}{...}
{title:The verbal report}

{pstd}
{cmd:causalimpact, report} prints a written interpretation, a faithful port of
{cmd:summary(impact, "report")} in R. It is meant as a starting draft for a
results section, not as a finished paragraph.

{pstd}
It has a fixed structure:

{phang2}
{bf:Paragraph 1} -- the average effect, with the counterfactual and its interval.

{phang2}
{bf:Paragraph 2} -- the cumulative effect, prefaced by the standing caveat that
sums "can only sometimes be meaningfully interpreted" (see
{help causalimpact_interpretation##columns:Average versus Cumulative}).

{phang2}
{bf:Paragraph 3} -- the relative effect as a percentage.

{phang2}
{bf:Paragraph 4}, printed only when needed -- a warning that the expected relative
effect is not the expected absolute effect over the expected prediction.

{phang2}
{bf:Paragraph 5} -- the significance verdict. The wording branches four ways on
(significant or not) x (positive or negative). When significant and positive it
adds the warning that statistical significance is not substantive significance,
and asks you to compare the effect against the goal of the intervention. When
not significant it lists the usual reasons: post-period too long, too short, or
controls too weak.

{phang2}
{bf:Paragraph 6} -- the tail-area probability, and whether the effect can be
called causal {it:if the model assumptions are satisfied}. That conditional is
load-bearing.

{pstd}
The prose also switches on significance in a subtle way that is easy to miss:
"{bf:By contrast, in} the absence of an intervention..." when the effect is
significant, versus a plain "{bf:In} the absence of an intervention..." when it
is not. Numbers in the report are abbreviated (3.51K, 1.2M) using the same
rounding rules as R, so they will look coarser than the table. Use
{cmd:digits()} to change the rounding, and {cmd:e(summary)} when you need full
precision.


{marker worked}{...}
{title:A worked reading}

{pstd}
From the R-vignette design, where the truth is a lift of exactly 10 units per
period over 30 periods:

{cmd}
    Actual                              117                       3511
    Prediction                        106.5                       3196
      95% CI               [    105.8,    107.2]     [     3175,     3216]
    Absolute effect                   10.51                      315.4
      95% CI               [    9.834,    11.23]     [      295,     336.9]
    Relative effect (%)               9.872                      9.872
      95% CI               [    9.173,   10.612]     [    9.173,   10.612]
    Posterior tail-area probability  p          0.00111  ***
{txt}

{pstd}
Read it as: on a typical post-period day the response was about 117, whereas
without the intervention we would have expected about 106.5. The daily effect is
therefore about 10.5 units, and we are 95% sure it lies between 9.8 and 11.2.
Over the whole 30-period window that accumulates to about 315 extra units, with
a 95% interval of [295, 337]. In relative terms the response is about 9.9%
higher than it would have been, interval [9.2%, 10.6%]. The probability of
seeing this by chance is at the resolution floor of the sampler, so the effect is
clearly significant.

{pstd}
Now the honest part. The truth is 10 per period and 300 cumulative; the estimate
is 10.5 and 315, about 5% high, and the 95% interval for the cumulative effect
does {bf:not} contain 300. That is not a failure of the command -- R returns
essentially the same answer on the same data. It happens because the single
covariate is an AR(0.999), effectively a unit root, so the counterfactual level
is genuinely uncertain and the model has drifted slightly. It is a good
illustration of the real lesson: {bf:the interval covers the model's uncertainty,
not the model's wrongness.} Weak or near-integrated controls shift the whole
counterfactual, and no credible interval will warn you about that.


{marker traps}{...}
{title:Ten ways to misread this output}

{phang2}
{bf:1.} Reading the Cumulative column for a stock quantity. Summing subscribers
across days produces a number, not a quantity.

{phang2}
{bf:2.} Treating a wide band as a defect. It is the model reporting honest
uncertainty about an unobservable.

{phang2}
{bf:3.} Assuming a significant overall effect means every period was affected.
Check panel B; individual periods may straddle zero.

{phang2}
{bf:4.} Assuming a non-significant overall effect means nothing happened. A short
burst can be swamped by a long quiet post-period.

{phang2}
{bf:5.} Reading a coefficient whose P(incl) is near zero. It has been shrunk to
almost nothing by model averaging.

{phang2}
{bf:6.} Reading P(b>0) for a rarely-included covariate. It is computed from a
handful of draws.

{phang2}
{bf:7.} Reading {cmd:_cons} as a structural intercept. It is confounded with the
local level.

{phang2}
{bf:8.} Reporting p = 0.00111 as a precise number. It is the sampler's floor at
{cmd:niter(1000)}.

{phang2}
{bf:9.} Extending the post-period to "get more data". It dilutes a decaying
effect and widens the band; it does not strengthen the finding.

{phang2}
{bf:10.} Calling the result causal without checking that the controls were
themselves untouched by the intervention. That assumption does all the work, and
no diagnostic in this output tests it.


{marker checklist}{...}
{title:Checklist before you believe a result}

{phang2}
{c 110} Were the controls plausibly unaffected by the intervention? Argue it
explicitly; no statistic here can check it.{p_end}
{phang2}
{c 110} Does the counterfactual track the observed series over the pre-period in
panel A?{p_end}
{phang2}
{c 110} Does a {bf:placebo run} on a date where nothing happened correctly return
nothing? This is the most informative single check you can run:{p_end}

{phang3}{cmd:. causalimpact y x1, pre(1 40) post(41 70) report}{p_end}

{phang2}
{c 110} Is the response a flow, if you are quoting the cumulative effect?{p_end}
{phang2}
{c 110} Is the post-period short enough that the relationship is still plausibly
stable?{p_end}
{phang2}
{c 110} Do the inclusion probabilities pick out controls that make substantive
sense?{p_end}
{phang2}
{c 110} Is the result stable across seeds, and across {cmd:priorlevelsd(0.01)}
versus {cmd:priorlevelsd(0.1)}? If the conclusion flips with the prior, report
that.{p_end}
{phang2}
{c 110} Did you state the priors and the assumptions when writing it up?{p_end}


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
{helpb causalimpact_rcheck:causalimpact rcheck},
{helpb causalimpact_postestimation:causalimpact postestimation}
{p_end}
