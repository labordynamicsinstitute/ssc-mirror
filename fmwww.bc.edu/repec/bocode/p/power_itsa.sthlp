{smcl}
{* *! version 1.0.0 02June2025}{...}
{title:Title}

{p2colset 5 19 20 2}{...}
{p2col:{hi:power itsa} {hline 2}} power and sample size analysis for single-group interrupted time series analysis (ITSA) {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:power itsa}
, {opth n(numlist)}
{opth int:ercept(numlist)}
{opth post:trend(numlist)}
[
{opth tr:period(numlist)}
{opth pre:trend(numlist)}
{opth st:ep(numlist)}
{opt sd(#)}
{opth a:lpha(numlist)}
{opth ac:orr(numlist)} 
{opt lev:el} 
{opt noi:sily} 
{opt reps(#)}
]



{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opth n(numlist)}}number of overall time periods in the study{p_end}
{p2coldent:* {opth int:ercept(numlist)}}intercept, or starting level of the outcome series {p_end}
{p2coldent:* {opth post:trend(numlist)}}post-intervention trend (slope) {p_end}
{synopt :{opth tr:period(numlist)}}time period when the intervention is introduced; default is the halfway point in the time series - {cmd:n()}  {p_end}
{synopt :{opth pre:trend(numlist)}}pre-intervention trend (slope); default is {cmd:pretrend(0)}{p_end}
{synopt :{opth st:ep(numlist)}}change in the level of the outcome immediately following the introduction of the intervention; default is {cmd:step(0)} {p_end}
{synopt :{opt sd(#)}}the standard deviation for adding variability in the data; default is {cmd:sd(1)}{p_end}
{synopt :{opth a:lpha(numlist)}}significance level; default is {cmd:alpha(0.05)}{p_end}
{synopt :{opth ac:orr(numlist)}}autocorrelation (rho); default is {cmd:acorr(0)}{p_end}
{synopt :{opt lev:el}}specify that power is based on a change in level; default is that power is based on a difference in pre- and post-intervention trends{p_end}
{synopt :{opt noi:sily}}show the simulation progress (dots); default is to suppress the simulation progress (dots) {p_end}
{synopt :{opt reps(#)}}the number of replications to be performed; default is {cmd:reps(100)} {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{cmd:* are required}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt power itsa} computes power for a specified number of time periods {cmd:n()} in a single-group interrupted time series analysis (ITSA) using simulation. 
The process involves (1) generating a time series using {helpb itsadgp}, based on the user-inputs replicating the coefficients of a single-group ITSA regression 
model (see Remarks section below)-- which may include autocorrelation for an autoregressive AR(1) model; (2) estimating an {helpb itsa:ITSA} model using Newey-West 
standard errors; (3) testing if the difference in pre- and post-intervention trends = 0, or when {cmd:level} is specified, testing if the change in level in the 
period immediately following introduction of the intervention (compared to the conterfactual) = 0; and (4) repeating this process 
the number of times specified in {cmd:reps()}.

{title:Remarks} 

{pstd}
Regression (with methods to account for autocorrelation) is the most commonly
used modeling technique in interrupted time series analyses. When there is
only one group under study (no comparison groups), the regression model
assumes the following form (Linden 2015):

{pmore}
Y_t = Beta_0 + Beta_1(T) + Beta_2(X_t) + Beta_3(TX_t)

{pstd}
Here Y_t is the aggregated outcome variable measured at each equally spaced
time point t, T is the time since the start of the study, X_t is a dummy
(indicator) variable representing the intervention (pre-intervention periods 0,
otherwise 1), and TX_t is an interaction term between X_t and a sequentially 
numbered variable starting in the period immediately following the intervention.

{pstd}
Beta_0 represents the intercept or starting level of the outcome variable. 
Beta_1 is the slope or trend of the outcome variable until the introduction 
of the intervention. Beta_2 represents the change in the level of the outcome 
that occurs in the period immediately following the introduction of the intervention 
(compared with the counterfactual). Beta_3 represents the difference between pre-intervention 
and post-intervention slopes of the outcome. Thus we look for significant p-values
in Beta_2 to indicate an immediate treatment effect, or in Beta_3 to indicate
a treatment effect over time (Linden 2015, 2017).



{title:Options}

{p 4 8 2} 
{opth n(numlist)} the total number of time periods in the study (i.e. including both pre- and post-intervention); {cmd:n() is required}.

{p 4 8 2} 
{opth int:ercept(numlist)} intercept, or starting level of the outcome series (Beta_0 in the model above); {cmd:intercept() is required}.

{p 4 8 2} 
{opth post:trend(numlist)} the post-intervention trend (which equals Beta_1 + Beta_3 in the model above); {cmd:posttrend() is required}. 

{p 4 8 2} 
{opth tr:period(numlist)} indicates in which time period the intervention was introduced. The default assumes that {cmd:trperiod()} is at 
the halfway point in the time series (or halfway + 1 for an even number of periods in the time series). It is recommended to leave 
{cmd:trperiod()} unspecified if a number of time periods {cmd:n} are specified so that the correct {cmd:trperiods()} are utilized.   

{p 4 8 2} 
{opth pre:trend(numlist)} the pre-intervention trend (Beta_1 in the model above). The default assumes that there is no pre-intervention
trend ({cmd:pretrend(0)}).

{p 4 8 2} 
{opth st:ep(numlist)} is the change in level of the outcome immediately following the introduction of the intervention compared to the 
counterfactual (i.e. what the predicted value of that time period would be absent the intervention -- Beta_2 in the model above). The 
default assumes that there is no step change ({cmd:step(0)}).

{p 4 8 2} 
{opt sd(#)} the standard deviation used for adding variability to the data in the data generating process. The default is {cmd:sd(1)}.

{p 4 8 2} 
{opth a:lpha(numlist)} significance level. The default is {cmd:alpha(0.05)}.

{p 4 8 2} 
{opth ac:orr(numlist)} the autocorrelation (rho) of an autoregressive 1 (AR(1)) model. The value(s) specified must be < 1.0. The default 
is {cmd:acorr(0)} indicating no autocorrelation.

{p 4 8 2} 
{opt lev:el} specifies that power is computed based on a change in level (Beta_2 in the model above). The default is that power is computed based 
on a difference in pre- and post-intervention trends (Beta_3 in the model above).

{p 4 8 2} 
{opt noi:sily} show the simulation progress (dots). The default is to suppress the simulation progress (dots).

{p 4 8 2} 
{opt reps(#)} specifies the number of replications to be performed. The default is {cmd:reps(100)} but a much higher number of repetitions should
be used to improve the accuracy of the estimates (at minimum 1000).



{title:Examples}

{pstd}
{opt 1) Computing power for a difference in pre- and post-intevention trends:}{p_end}

{pstd}We want to estimate the power for detecting a change from a pre-intervention trend of 0 to a 
post-intervention trend of 0.20 (because the pre-trend = 0, the difference in trends of 0.20 also represents 
a percent change of 20%). The starting level (intercept) is set to 500, the number of time periods we plan to 
observe is 34, and the intervention will be introduced at the halfway point (17). We do not believe that 
there will be an immediate effect of the intervention, so we set step to 0. In reviewing past data we 
found that the autocorrelation of the time series = 0.20. We set the repetitions to 100, but will increase 
the reps to {ul:at least 1000} after we have established that the program is producing reasonable results.  {p_end}

{phang2}{cmd:. power itsa, n(34) intercept(500) trperiod(17) step(0) posttrend(0.20) acorr(.20) alpha(0.05) reps(100) table(,labels(N "N-periods")) }{p_end}

{pstd}Same as above, but we now add a couple of additional time periods. We {ul:do not} specify {cmd:trperiod()} so that the program
will use the default halfway point(s) in the time series (specified as {cmd:n}). We also specify {cmd:noisily} to see the progress {p_end}

{phang2}{cmd:. power itsa, n(32(2)36) intercept(500) step(0) posttrend(0.20) acorr(.20) alpha(0.05) reps(100) table(,labels(N "N-periods")) noi} {p_end}

{pstd}Same as above, but we now specify two autocorrelation values (0.20 and 0.30) {p_end}

{phang2}{cmd:. power itsa, n(32(2)36) intercept(500) step(0) posttrend(0.20) acorr(.20 .30) alpha(0.05) reps(100) table(,labels(N "N-periods")) noi} {p_end}

{pstd}Same as above, but we now graph the results {p_end}

{phang2}{cmd:. power itsa, n(32(2)36) intercept(500) step(0) posttrend(0.20) acorr(.20 .30) alpha(0.05) reps(100) table(,labels(N "N-periods")) graph noi} {p_end}

{pstd}Same as above, but we now add an additional alpha of 0.01 {p_end}

{phang2}{cmd:. power itsa, n(32(2)36) intercept(500) step(0) posttrend(0.20) acorr(.20 .30) alpha(0.01 0.05) reps(100) table(,labels(N "N-periods")) graph noi} {p_end}


{pstd}
{opt 2) Computing power for a change in level (actual vs the counterfactual) :}{p_end}

{pstd}We now want to estimate power for detecting a treatment effect that we believe will cause an immediate jump in 
the time series, but will not continue to increase over time. The intercept (starting value) is set at 120, the number
of time periods we plan to observe is 20, and the intervention will be introduced at the halfway mark of 10. We don't
expect a pre-intervention trend or a post-intervention trend so we set them both to 0. We believe that the step (difference
between the actual level and the counterfactual level, in the period immediately following introduction of the intervention) will
increase by about 2%, so we specify {cmd:step(2.4)}. Review of past values in the time series suggests that the autocorrelation = 0.1.
Here we specify the {cmd:level} option to ensure that the coefficient Beta_2 is evaluated.    {p_end}

{phang2}{cmd:. power itsa, n(20) intercept(120) trperiod(10) step(2.4) posttrend(0) acorr(.10) alpha(0.05) reps(100) table(,labels(N "N-periods")) level noi}{p_end}

{pstd}Same as above but we now add two additional time periods to evaluate. We {ul:do not} include {cmd:trperiod} as an option to allow the
program to use the default halfway marks of the time series for the start of the intervention. {p_end}

{phang2}{cmd:. power itsa, n(20 22 24) intercept(120) step(2.4) posttrend(0) acorr(.10) alpha(0.05) reps(100) table(,labels(N "N-periods")) level noi}{p_end}

{pstd}Same as above but we now add an alpha of 0.01. {p_end}

{phang2}{cmd:. power itsa, n(20 22 24) intercept(120) step(2.4) posttrend(0) acorr(.10) alpha(0.01 0.05) reps(100) table(,labels(N "N-periods")) level noi}{p_end}

{pstd}Same as above, but we now graph the results {p_end}

{phang2}{cmd:. power itsa, n(20 22 24) intercept(120) step(2.4) posttrend(0) acorr(.10) alpha(0.01 0.05) reps(100) table(,labels(N "N-periods")) graph level noi}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:power itsa} stores the following in {cmd:r()}:

{synoptset 14 tabbed}{...}
{p2col 5 14 18 2: Scalars}{p_end}
{synopt:{cmd:r(power)}}power for the computed sample size{p_end}
{synopt:{cmd:r(beta)}}probability of a type II error{p_end}
{synopt:{cmd:r(alpha)}}significance level{p_end}
{synopt:{cmd:r(N)}}computed sample size{p_end}
{synopt:{cmd:r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}
{synopt:{cmd:r(acorr)}}autocorrelation (rho){p_end}
{synopt:{cmd:r(sd)}}specified standard deviation for generating randomness{p_end}
{synopt:{cmd:r(posttrend)}}specified post-intervention trend{p_end}
{synopt:{cmd:r(step)}}specified step (change in level){p_end}
{synopt:{cmd:r(pretrend)}}specified pre-intervention trend{p_end}
{synopt:{cmd:r(intercept)}}specified intercept (starting level of the time series){p_end}
{synopt:{cmd:r(trperiod)}}time period of when the intervention was introduced{p_end}
{synopt:{cmd:r(separator)}}number of lines between separator lines in the table{p_end}
{synopt:{cmd:r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}{cmd:itsa}{p_end}
{synopt:{cmd:r(columns)}}displayed table columns{p_end}
{synopt:{cmd:r(labels)}}table column labels{p_end}
{synopt:{cmd:r(widths)}}table column widths{p_end}
{synopt:{cmd:r(formats)}}table column formats{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(pss_table)}}table of results{p_end}
{p2colreset}{...}



{title:References}

{phang}
Linden, A. 2015.
{browse "http://www.stata-journal.com/article.html?article=st0389":Conducting interrupted time series analysis for single and multiple group comparisons}.
{it:Stata Journal}.
15: 480-500.

{phang}
---------. 2017.
{browse "http://www.stata-journal.com/article.html?article=st0389_3":A comprehensive set of postestimation measures to enrich interrupted time-series analysis}.
{it:Stata Journal}
17: 73-88.

{phang}
---------. 2022.
{browse "https://journals.sagepub.com/doi/full/10.1177/1536867X221083929":Erratum: A comprehensive set of postestimation measures to enrich interrupted time-series analysis}.
{it:Stata Journal}
22: 231-233. 



{marker citation}{title:Citation of {cmd:power itsa}}

{p 4 8 2}{cmd:power itsa} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). POWER ITSA: Stata module to compute power and sample size for a single-group interrupted time series analysis (ITSA)



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb power}, {helpb simulate}, {helpb itsa} (if installed), {helpb itsadgp} (if installed) {p_end}

