{smcl}
{* *! version 3.1.0 12Feb2026}{...}
{* *! version 3.0.0 12Jan2026}{...}
{* *! version 2.1.0 24Jul2025}{...}
{* *! version 2.0.0 11June2025}{...}
{* *! version 1.0.1 08June2025}{...}
{* *! version 1.0.0 02June2025}{...}
{title:Title}

{p2colset 5 19 20 2}{...}
{p2col:{hi:power itsa} {hline 2}} power analysis for single and multiple-group interrupted time series analysis {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Power for a single-group interrupted time series analysis:

{p 8 12 2}
{cmd:power single_itsa}, 
{opth n(numlist)} 
{opth int:ercept(numlist)}
{opth post:trend(numlist)}
{opt [} {opth tr:period(numlist)}
{opth pre:trend(numlist)}
{opth st:ep(numlist)}
{opt sd(#)}
{opth ac:orr(numlist)} 
{opth a:lpha(numlist)}
{opt lev:el} 
{opt noi:sily}  {p_end}
{p 12 14 2}
{opt seed(#)}
{opt prais}
{opt perf}
{opth rep:s(numlist)} {opt ]} 


{pstd}
Power for a multiple-group interrupted time series analysis:

{p 8 12 2}
{cmd:power multi_itsa}, 
{opth n(numlist)} 
{opth tint:ercept(numlist)}
{opth tpost:trend(numlist)}
{opth cint:ercept(numlist)}
{opth cpost:trend(numlist)}
{opt [} {opth tr:period(numlist)}
{opth contc:nt(numlist)}
{opth tpre:trend(numlist)}  {p_end}
{p 12 14 2}
{opth tst:ep(numlist)}
{opt tsd(#)}
{opth tac:orr(numlist)} 
{opth cpre:trend(numlist)}
{opth cst:ep(numlist)} 
{opt csd(#)}
{opth cac:orr(numlist)} 
{opth a:lpha(numlist)}
{opt lev:el} 
{opt noi:sily}
{opt seed(#)}
{opt prais}
{opt perf}
{opth rep:s(numlist)} {opt ]} 


{pstd}
In the syntax for {cmd:power multi_itsa}, all options beginning with the letter "t" refer to the {it:treated} unit, and all options beginning with the letter "c" refer to {it:controls}



{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Single-group ITSA}
{p2coldent:* {opth n(numlist)}}total number of time periods in the study{p_end}
{p2coldent:* {opth int:ercept(numlist)}}intercept, or starting level of the outcome series {p_end}
{p2coldent:* {opth post:trend(numlist)}}post-intervention trend (slope) {p_end}
{synopt :{opth tr:period(numlist)}}time period when the intervention is introduced; default is the halfway point in the time series - {cmd:n()}  {p_end}
{synopt :{opth pre:trend(numlist)}}pre-intervention trend (slope); default is {cmd:pretrend(0)}{p_end}
{synopt :{opth st:ep(numlist)}}change in the level of the outcome immediately following the introduction of the intervention; default is {cmd:step(0)} {p_end}
{synopt :{opt sd(#)}}the standard deviation for adding variability in the data; default is {cmd:sd(1)}{p_end}
{synopt :{opth ac:orr(numlist)}}autocorrelation (rho); default is {cmd:acorr(0)}{p_end}
{synopt :{opth a:lpha(numlist)}}significance level; default is {cmd:alpha(0.05)}{p_end}
{synopt :{opt lev:el}}specify that power is based on a change in level; default is that power is based on a difference in pre- and post-intervention trends{p_end}
{synopt :{opt noi:sily}}show the simulation progress (dots); default is to suppress the simulation progress (dots) {p_end}
{synopt :{opt seed(#)}}set random-number seed to {it:#}{p_end}
{synopt :{opt prais}}fit a {helpb prais} model (and all available model options). Default is to fit a {helpb glm} model with Newey-West standard errors {p_end}
{synopt:{opt perf}}present performance measures in table output {p_end}
{synopt :{opth rep:s(numlist)}}the number of replications to be performed; default is {cmd:reps(100)} {p_end}

{syntab:Multiple-group ITSA}
{p2coldent:* {opth n(numlist)}}total number of time periods in the study{p_end}
{p2coldent:* {opth tint:ercept(numlist)}}treated unit's intercept, or starting level of the outcome series {p_end}
{p2coldent:* {opth tpost:trend(numlist)}}treated unit's post-intervention trend (slope) {p_end}
{p2coldent:* {opth cint:ercept(numlist)}}control's intercept, or starting level of the outcome series {p_end}
{p2coldent:* {opth cpost:trend(numlist)}}control's post-intervention trend (slope) {p_end}
{synopt :{opth tr:period(numlist)}}time period when the intervention is introduced; default is the halfway point in the time series - {cmd:n()}  {p_end}
{synopt :{opth contc:nt(numlist)}}the number of control units to be generated; default is {cmd:contcnt(1)} {p_end}
{synopt :{opth tpre:trend(numlist)}}treated unit's pre-intervention trend (slope); default is {cmd:tpretrend(0)}{p_end}
{synopt :{opth tst:ep(numlist)}}treated unit's change in the level of the outcome immediately following the introduction of the intervention; default is {cmd:tstep(0)} {p_end}
{synopt :{opt tsd(#)}}the standard deviation for adding variability to the treated unit's data; default is {cmd:tsd(1)}{p_end}
{synopt :{opth tac:orr(numlist)}}treated unit's autocorrelation (rho); default is {cmd:tacorr(0)}{p_end}
{synopt :{opth pre:trend(numlist)}}control's pre-intervention trend (slope); default is {cmd:cpretrend(0)}{p_end}
{synopt :{opth st:ep(numlist)}}control's change in the level of the outcome immediately following the introduction of the intervention; default is {cmd:cstep(0)} {p_end}
{synopt :{opt sd(#)}}the standard deviation for adding variability to the control's data; default is {cmd:csd(1)}{p_end}
{synopt :{opth ac:orr(numlist)}}control's autocorrelation (rho); default is {cmd:cacorr(0)}{p_end}
{synopt :{opt lev:el}}specify that power is based on changes in level; default is that power is based on differences in pre- and post-intervention trends{p_end}
{synopt :{opt noi:sily}}show the simulation progress (dots); default is to suppress the simulation progress (dots) {p_end}
{synopt :{opt seed(#)}}set random-number seed to {it:#}{p_end}
{synopt :{opt prais}}fit a {helpb prais} model. Default is to fit a {helpb glm} model with Newey-West standard errors {p_end}
{synopt:{opt perf}}present performance measures in table output {p_end}
{synopt :{opth rep:s(numlist)}}the number of replications to be performed; default is {cmd:reps(100)} {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{cmd:* are required}{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt power itsa} computes power for a specified number of time periods {cmd:n()} in a single-group or multiple-group interrupted time series analysis (ITSA), using simulation. 
For a single-group ITSA, the process involves (1) generating a time series using {helpb itsadgp}, based on the user-inputs replicating the coefficients of a single-group ITSA 
regression model (see Remarks section below)-- which may include autocorrelation for an autoregressive AR(1) model; (2) estimating a single-group {helpb itsa:ITSA} model using 
either regression with Newey-West standard errors or Prais-Winsten regression; (3) testing if the difference in pre- and post-intervention trends = 0, or when {cmd:level} is 
specified, testing if the change in level in the period immediately following introduction of the intervention (compared to the conterfactual) = 0; and (4) repeating this process 
the number of times specified in {cmd:reps()}. For a multiple-group group ITSA, the process involves (1) generating one time series for the treated unit and one or more time 
series for the controls, replicating the coefficients of a multiple-group ITSA regression model (see Remarks section below)-- which may include separate autocorrelations for 
the treated unit and controls; (2) estimating a multiple-group {helpb itsa:ITSA} model using either regression with Newey-West standard errors or Prais-Winsten regression; 
(3) testing if the difference in differences of the pre- and post-intervention trends = 0, or when {cmd:level} is specified, testing if the differences in the change in level 
in the period immediately following introduction of the intervention (compared to the conterfactual) = 0; and (4) repeating this process the number of times specified in {cmd:reps()}.


{title:Remarks} 

{pstd}
Regression (with methods to account for autocorrelation) is the most commonly
used modeling technique in interrupted time series analyses. When there is
only one group under study (no comparison groups), the regression model
assumes the following form (Linden 2015):

{pmore}
Y_t = Beta_0 + Beta_1(T) + Beta_2(X_t) + Beta_3(TX_t){space 5}(1)

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

{pstd}
When one or more control groups are available for comparison, the regression
model in (1) is expanded to include four additional terms (Beta_4 to Beta_7)
(Linden 2015, 2017):

{pmore} Y_t = Beta_0 + Beta_1(T) + Beta_2(X_t) + Beta_3(TX_t) +
Beta_4(Z) + Beta_5(ZT) + Beta_6(ZX_t) + Beta_7(ZTX_t){space 5}(2)

{pstd}
Here Z is a dummy variable to denote the cohort assignment (treatment or
control), and ZT, ZX_t, and ZTX_t are all interaction terms among previously
described variables. Now the coefficients Beta_0 to Beta_3 represent the
control group, and the coefficients Beta_4 to Beta_7 represent values of the
treatment group. More specifically, Beta_4 represents the difference in the
level (intercept) of the dependent variable between treatment and controls
prior to the intervention, Beta_5 represents the difference in the slope
(trend) of the dependent variable between treatment and controls prior to the
intervention, Beta_6 indicates the difference between treatment and control
groups in the level of the dependent variable immediately following
introduction of the intervention, and Beta_7 represents the difference between
treatment and control groups in the slope (trend) of the dependent variable
after initiation of the intervention compared with preintervention (akin to a
difference-in-differences of slopes).

{pstd}
The two parameters Beta_4 and Beta_5 play a particularly important role in
establishing whether the treatment and control groups are balanced on both the
level and the trajectory of the dependent variable in the preintervention
period. If these data were from a randomized controlled trial, we would
expect similar levels and slopes prior to the intervention. However, in an
observational study where equivalence between groups cannot be ensured, any
observed differences will likely raise concerns about the ability to draw
causal inferences about the relationship between the intervention and the
outcomes (Linden 2015, 2017).



{title:Options}

{pstd}
    {cmd:Single-group ITSA}

{p 6 8 2} 
{opth n(numlist)} the total number of time periods in the study (i.e. including both pre- and post-intervention); {cmd:n() is required}.

{p 6 8 2} 
{opth int:ercept(numlist)} intercept, or starting level of the outcome series (Beta_0 in model 1 above); {cmd:intercept() is required}.

{p 6 8 2} 
{opth post:trend(numlist)} the post-intervention trend (which equals Beta_1 + Beta_3 in model 1 above); {cmd:posttrend() is required}. 

{p 6 8 2} 
{opth tr:period(numlist)} indicates in which time period the intervention was introduced. The default assumes that {cmd:trperiod()} is at 
the halfway point in the time series (or halfway + 1 for an even number of periods in the time series). It is recommended to leave 
{cmd:trperiod()} unspecified if a number of time periods {cmd:n} are specified so that the correct {cmd:trperiods()} are utilized.   

{p 6 8 2} 
{opth pre:trend(numlist)} the pre-intervention trend (Beta_1 in model 1 above). The default assumes that there is no pre-intervention
trend ({cmd:pretrend(0)}).

{p 6 8 2} 
{opth st:ep(numlist)} is the change in level of the outcome immediately following the introduction of the intervention compared to the 
counterfactual (i.e. what the predicted value of that time period would be absent the intervention -- Beta_2 in model 1 above). The 
default assumes that there is no step change ({cmd:step(0)}).

{p 6 8 2} 
{opt sd(#)} the standard deviation used for adding variability to the data in the data generating process. The default is {cmd:sd(1)}.

{p 6 8 2} 
{opth ac:orr(numlist)} the autocorrelation (rho) of an autoregressive 1 (AR(1)) model. The value(s) specified must be < 1.0. The default 
is {cmd:acorr(0)} indicating no autocorrelation.

{p 6 8 2} 
{opth a:lpha(numlist)} significance level. The default is {cmd:alpha(0.05)}.

{p 6 8 2} 
{opt lev:el} specifies that power is computed based on a change in level (Beta_2 in model 1 above). The default is that power is computed based 
on a difference in pre- and post-intervention trends (Beta_3 in model 1 above).

{p 6 8 2} 
{opt noi:sily} show the simulation progress (dots). The default is to suppress the simulation progress (dots).

{p 6 8 2} 
{opt seed(#)} sets the random-number seed for the simulations.

{p 6 8 2} 
{opt prais} fits a {helpb prais} model (with all available model options). If {cmd:prais} is
not specified, {cmd:itsa} will use {helpb glm} with Newey-West standard errors, 
as the default model. 

{p 6 8 2} 
{opt perf} requests that the following model performance measures be added to the output table: percent bias, root mean squared error, 
confidence interval coverage, empirical standard errors. The confidence interval coverage will be computed based on the specified alpha level(s). 


{p 6 8 2} 
{opth rep:s(numlist)} specifies the number of replications to be performed. The default is {cmd:reps(100)} but a much higher number of repetitions should
be used to improve the accuracy of the estimates (at minimum 1000).



{pstd}
    {cmd:Multiple-group ITSA}

{p 6 8 2} 
{opth n(numlist)} the total number of time periods in the study (i.e. including both pre- and post-intervention); {cmd:n() is required}.

{p 6 8 2} 
{opth contcnt(numlist)} the number of control units to be generated; default is {cmd:contcnt(1)}.

{p 6 8 2} 
{opth tint:ercept(numlist)} the treated unit's intercept, or starting level of the outcome series (Beta_0 + Beta_4, in model 2 above); {cmd:tintercept() is required}.

{p 6 8 2} 
{opth tpost:trend(numlist)} the treated unit's post-intervention trend (Beta_1 + Beta_3 + Beta_5 + Beta_7, in model 2 above); {cmd:tposttrend() is required}. 

{p 6 8 2} 
{opth cint:ercept(numlist)} the control's intercept, or starting level of the outcome series (Beta_0, in model 2 above); {cmd:cintercept() is required}.

{p 6 8 2} 
{opth cpost:trend(numlist)} the control's post-intervention trend (Beta_1 + Beta_2, in model 2 above); {cmd:cposttrend() is required}. 

{p 6 8 2} 
{opth tr:period(numlist)} indicates in which time period the intervention was introduced. The default assumes that {cmd:trperiod()} is at 
the halfway point in the time series (or halfway + 1 for an even number of periods in the time series). It is recommended to leave 
{cmd:trperiod()} unspecified if a number of time periods {cmd:n} are specified so that the correct {cmd:trperiods()} are utilized.

{p 6 8 2} 
{opth tpre:trend(numlist)} the treated unit's pre-intervention trend (Beta_1 + Beta_5, in model 2 above). The default assumes that there is no pre-intervention
trend ({cmd:tpretrend(0)}).

{p 6 8 2} 
{opth tst:ep(numlist)} the treated unit's change in level of the outcome immediately following the introduction of the intervention compared to the 
counterfactual (i.e. what the predicted value of that time period would be absent the intervention -- Beta_2 + Beta_6, in model 2 above). The 
default assumes that there is no step change ({cmd:tstep(0)}).

{p 6 8 2} 
{opt tsd(#)} the standard deviation used for adding variability to treated unit's data in the data generating process. The default is {cmd:tsd(1)}.

{p 6 8 2} 
{opth tac:orr(numlist)} the treated unit's autocorrelation (rho) of an autoregressive 1 (AR(1)) model. The value(s) specified must be < 1.0. The default 
is {cmd:tacorr(0)} indicating no autocorrelation.

{p 6 8 2} 
{opth cpre:trend(numlist)} the control's pre-intervention trend (Beta_1, in model 2 above). The default assumes that there is no pre-intervention
trend ({cmd:cpretrend(0)}).

{p 6 8 2} 
{opth cst:ep(numlist)} the control's change in level of the outcome immediately following the introduction of the intervention compared to the 
counterfactual (i.e. what the predicted value of that time period would be absent the intervention -- Beta_2, in model 2 above). The 
default assumes that there is no step change ({cmd:cstep(0)}).

{p 6 8 2} 
{opt csd(#)} the standard deviation used for adding variability to the control's data in the data generating process. The default is {cmd:csd(1)}, but 
should increased with substantially as the number of control units is added via {cmd:contcnt()}.

{p 6 8 2} 
{opth cac:orr(numlist)} the control's autocorrelation (rho) of an autoregressive 1 (AR(1)) model. The value(s) specified must be < 1.0. The default 
is {cmd:cacorr(0)} indicating no autocorrelation.

{p 6 8 2} 
{opth a:lpha(numlist)} significance level. The default is {cmd:alpha(0.05)}.

{p 6 8 2} 
{opt lev:el} specifies that power is computed based on a difference in the change in level (Beta_6, in model 2 above). The default is that power is 
computed based on a difference in differences of pre- and post-intervention trends (Beta_7, in model 2 above).

{p 6 8 2} 
{opt noi:sily} show the simulation progress (dots). The default is to suppress the simulation progress (dots).

{p 6 8 2} 
{opt seed(#)} sets the random-number seed for the simulations.

{p 6 8 2} 
{opt prais} fits a {helpb prais} model (with all available model options). If {cmd:prais} is
not specified, {cmd:itsa} will use {helpb glm} with Newey-West standard errors, 
as the default model. 

{p 6 8 2} 
{opt perf} requests that the following model performance measures be added to the output table: percent bias, root mean squared error, 
confidence interval coverage, empirical standard errors. The confidence interval coverage will be computed based on the specified alpha level(s). 

{p 6 8 2} 
{opth rep:s(numlist)} specifies the number of replications to be performed. The default is {cmd:reps(100)} but a much higher number of repetitions should
be used to improve the accuracy of the estimates (at minimum 1000).



{title:Examples}

{pstd}
{opt Single-group ITSA}

{pstd}
{opt 1) Computing power for a difference in pre- and post-intevention trends:}{p_end}

{pstd}We want to estimate the power for detecting a change from a pre-intervention trend of 0 to a 
post-intervention trend of 0.20 (because the pre-trend = 0, the difference in trends of 0.20 also represents 
a percent change of 20%). The starting level (intercept) is set to 500, the number of time periods we plan to 
observe is 34, and the intervention will be introduced at the halfway point (17). We do not believe that 
there will be an immediate effect of the intervention, so we set step to 0. In reviewing past data we 
found that the autocorrelation of the time series = 0.20. We set the repetitions to 100, but will increase 
the reps to {ul:at least 1000} after we have established that the program is producing reasonable results.  {p_end}

{phang2}{cmd:. power single_itsa, n(34) intercept(500) trperiod(17) step(0) posttrend(0.20) acorr(.20) alpha(0.05) reps(100) table(,labels(N "N-periods")) }{p_end}

{pstd}Same as above, but we now add a couple of additional time periods. We {ul:do not} specify {cmd:trperiod()} so that the program
will use the default halfway point(s) in the time series (specified as {cmd:n}). We also specify {cmd:noisily} to see the progress {p_end}

{phang2}{cmd:. power single_itsa, n(32(2)36) intercept(500) step(0) posttrend(0.20) acorr(.20) alpha(0.05) reps(100) table(,labels(N "N-periods")) noi} {p_end}

{pstd}Same as above, but we now specify two autocorrelation values (0.20 and 0.30) and specify that a Prais-Winsten model be computed {p_end}

{phang2}{cmd:. power single_itsa, n(32(2)36) intercept(500) step(0) posttrend(0.20) acorr(.20 .30) alpha(0.05) reps(100) table(,labels(N "N-periods")) noi prais} {p_end}

{pstd}Same as above, but we now graph the results {p_end}

{phang2}{cmd:. power single_itsa, n(32(2)36) intercept(500) step(0) posttrend(0.20) acorr(.20 .30) alpha(0.05) reps(100) table(,labels(N "N-periods")) graph noi prais} {p_end}

{pstd}Same as above, but we now add an additional alpha of 0.01 {p_end}

{phang2}{cmd:. power single_itsa, n(32(2)36) intercept(500) step(0) posttrend(0.20) acorr(.20 .30) alpha(0.01 0.05) reps(100) table(,labels(N "N-periods")) graph noi} {p_end}


{pstd}
{opt 2) Computing power for a change in level (actual vs the counterfactual) :}{p_end}

{pstd}We now want to estimate power for detecting a treatment effect that we believe will cause an immediate jump in 
the time series, but will not continue to increase over time. The intercept (starting value) is set at 120, the number
of time periods we plan to observe is 20, and the intervention will be introduced at the halfway mark of 10. We don't
expect a pre-intervention trend or a post-intervention trend so we set them both to 0. We believe that the step (difference
between the actual level and the counterfactual level, in the period immediately following introduction of the intervention) will
increase by about 2%, so we specify {cmd:step(2.4)}. Review of past values in the time series suggests that the autocorrelation = 0.1.
Here we specify the {cmd:level} option to ensure that the coefficient Beta_2 is evaluated.    {p_end}

{phang2}{cmd:. power single_itsa, n(20) intercept(120) trperiod(10) step(2.4) posttrend(0) acorr(.10) alpha(0.05) reps(100) table(,labels(N "N-periods")) level noi}{p_end}

{pstd}Same as above but we now add two additional time periods to evaluate. We {ul:do not} include {cmd:trperiod} as an option to allow the
program to use the default halfway marks of the time series for the start of the intervention. {p_end}

{phang2}{cmd:. power single_itsa, n(20 22 24) intercept(120) step(2.4) posttrend(0) acorr(.10) alpha(0.05) reps(100) table(,labels(N "N-periods")) level noi}{p_end}

{pstd}Same as above but we now add an alpha of 0.01 and request model performance data. {p_end}

{phang2}{cmd:. power single_itsa, n(20 22 24) intercept(120) step(2.4) posttrend(0) acorr(.10) alpha(0.01 0.05) reps(100) table(,labels(N "N-periods")) level noi perf}{p_end}

{pstd}Same as above, but we now graph the results {p_end}

{phang2}{cmd:. power single_itsa, n(20 22 24) intercept(120) step(2.4) posttrend(0) acorr(.10) alpha(0.01 0.05) reps(100) table(,labels(N "N-periods")) graph level noi}{p_end}


{pstd}
{opt Multiple-group ITSA}

{pstd}
{opt 1) Computing power for a difference in differences of pre- and post-intevention trends:}{p_end}

{pstd} In the first example of a multiple-group ITSA in the {helpb itsa} package, the difference-in-differences in trends (the coefficient for _z_x_t1989) is not statistically
significant ({it:P} = 0.136). Here we reestimate that model because we'll need some of the coefficients for the subsequent power calculations:

{pmore}
Load data and declare the dataset as panel: {p_end}

{phang2}{cmd:. use cigsales, clear}{p_end}
{phang2}{cmd:. tsset state year}{p_end}

{phang2}{cmd:. itsa cigsale, treatid(3) trperiod(1989) lag(1) fig posttrend replace}{p_end}

{pstd} Now we want to compute how many time periods will be necessary for the difference-in-differences in trends (_z_x_t) to reach {it:P} < 0.05 at 80% power.
We set {opt n} to a range from 32 to 42 time periods in increments of 1, since we know from the actual data that 31 time periods was not sufficient to elicit
a {it:P}-value < 0.05. We leave the {opt trperiod()} at the original 20, since the only thing that will be added are additional post-intervention periods. 
All of the treated unit's and controls' specifications are taken from the output of the original model (see the description of each option above in the Options section).
We set {opt tsd()} to 2 to account for the minor variability in the treated unit's data, we set the number of control units to be generated as 39 and we set {opt csd()} 
to 30 to account for large variability amongst the control units. We also treat all states as if they have the same amount of autocorrelation (rho = 0.20), although we 
could specify different amounts for treatment and control. Finally, we specify the {opt noisily} option to see the simulation progress:

{phang2}{cmd:. power multi_itsa, n(32(1)42) trperiod(20) contcnt(39) tint(132.2258) tpre(-1.779474) tpost(-3.274126) /// } {p_end}
{phang3}{cmd: tstep(-20.0581) tsd(2) tacorr(.20) cint(135.4995) cpre(-.5477701) cpost(-1.051279) ///} {p_end}
{phang3}{cmd: cstep(-17.25168) csd(30) cacorr(.20) reps(1000) noi alpha(0.05)}{p_end}

{pstd} We see that it will require about 38 time periods (with the intervention introduced at time period 20) for the _z_x_t coefficient to achieve P < 0.05 at around 80% power. 


{pstd} In this example, researchers are planning to conduct a prospective longitudinal study in which one medical group will be given an artificial intelligence (AI) tool
to assist in diagnosing patients' ailments. The researchers hypothesize that the AI tool will reduce repeat office visits over time. 10 other medical groups will serve 
as controls and will not be given the AI tool. We want to estimate how long the study should last in order to detect a statistically significant ({it:P} < 0.05) decrease in weekly 
office visits with 80% power. Since the study groups will be matched (and therefore comparable on baseline level and trend), the intercepts for both groups are set to 500 weekly visits, 
and the pre-intervention trends of both groups are set to 0. The researchers don't expect to see a step change, since it will take time for the AI tool to achieve an effect. 
Therefore, the step option for both groups is also set to 0. The post-intervention trend for the control group is set to 0 since no change is expected in that group. However, the treated
unit is expected to experience a decreased trend of 2 office visits per week. We set the number of time periods to range from 14 to 18 weeks, in increments of 1. We use the 
default treatment period to start at the halfway mark in the time series:

{phang2}{cmd:. power multi_itsa, n(14(1)18) contcnt(10) tint(500) cint(500) tpre(0) cpre(0) tstep(0) cstep(0) tsd(2) csd(8) /// } {p_end}
{phang3}{cmd: cpost(0) tpost(-2) tacorr(.20) cacorr(.20) reps(1000) noi alpha(0.05) table graph} {p_end}

{pstd} We see that it will require about 17 weeks for the _z_x_t coefficient to achieve P < 0.05 at about 80% power when the intervention is introduced at the halfway point in the time series.


{pstd}
{opt 2) Computing power for a difference in the change in level (actual vs the counterfactual) :}{p_end}

{pstd}Revisiting the first example of a multiple-group ITSA in the {helpb itsa} package, the difference in the change in level/step (the coefficient for _z_x1989) is 
not statistically significant ({it:P} = 0.631). Here we want to compute how large of a difference between the change in level of the treatment group versus the controls
(_z_x)  would be necessary for the difference in the change in level to reach {it:P} < 0.05 at 80% power. The treatment group's step change in 1989 is -20.0581 (which is the
difference between the counterfactual [i.e. no intervention] of 98.416 and the predicted value with the intervention of 78.842, thus 20.38% decrease in 1989). The control
group's step change is -17.25168 (therefore _z_x = -2.806417). Here we test the treatment's step function as an decrease in cigarette sales of between 25% and 39% in increments 
of 1%. We derive the input values by multiplying the counterfactual by the desired percent decrease, e.g. 98.42 * -0.25 = -24.60 for a 25% decrease. We leave the 
controls' step as-is:

{phang2}{cmd:. power multi_itsa, n(31) trperiod(20) contcnt(39) tint(132.2258) tpre(-1.779474) tpost(-3.274126) /// } {p_end}
{phang3}{cmd: tstep(-24.60 -25.59 -26.57 -27.56 -28.54  -29.52)  tsd(2) tacorr(.20) cint(135.4995) ///} {p_end}
{phang3}{cmd: cpre(-.5477701) cpost(-1.051279) cstep(-17.25168) csd(6) cacorr(.20) reps(1000) noi alpha(0.05) level}{p_end}

{pstd}The results show that a decrease of about 30% in the treatment group's level (relative to the controls) would produce approximately 80% power to 
detect a difference at {it:P} < 0.05. 


{pstd} In this example, administrators of medical group will activate a new prompt in the electronic health record (EHR) of one primary care office that will require 
staff to enter patient responses to a mental health questionnaire. Another 3 comparable primary care offices will serve as a control group in which the prompt will 
not be activated. The hypothesis is that there will be an near immediate increase of 50% in the number of daily questionnaires entered into the EHR in the treated unit. 
The starting level of both treated and controls is 30 daily questionnaires entered. The pre-intervention trend of both groups is 0, and the post-intervention trend is 
also 0 for both groups since the effect is expected to be immediate and not increasing over time. The step for the treated unit is 15 (50% higher than 30 the starting
level and given that the controls are not expected to see any change in their survey uptake). The administrators want to estimate how many days it will take for the 50%
predicted increase in questionnaire response entry will achieve statistical significance ({it:P} < 0.05 at 80% power). We test a range of 10 to 15 days in an increment
of 1 day. We specify 1000 repetitions. Most importantly, we specify the "level" option to indicate that we're interested in estimating the differences in the change in
level between the groups. 

{phang2}{cmd:. power multi_itsa, n(10(1)15) contcnt(3) tint(30) cint(30) tpre(0) cpre(0) tstep(15) cstep(0) tsd(2) csd(6) /// } {p_end}
{phang3}{cmd: cpost(0) tpost(0)  tacorr(.20) cacorr(.20) reps(1000) alpha(0.05) table level noi} {p_end}

{pstd}The results show that it will take about 13 days after activating the prompt (total of 26 days pre- and post-activation) for a 50% increase in the treated office's 
change in level (relative to controls) to produce statistical significance (at {it:P} < 0.05) with approximately 80% power. 



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:power itsa} stores the following in {cmd:r()}:

{synoptset 17 tabbed}{...}
{pstd} {cmd:Single-group ITSA}{p_end}

{p2col 5 14 18 2: Scalars}{p_end}
{synopt:{cmd:r(power)}}power for the computed sample size{p_end}
{synopt:{cmd:r(beta)}}probability of a type II error{p_end}
{synopt:{cmd:r(alpha)}}significance level{p_end}
{synopt:{cmd:r(N)}}computed sample size{p_end}
{synopt:{cmd:r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}
{synopt:{cmd:r(reps)}}the number of repetitions{p_end}
{synopt:{cmd:r(acorr)}}autocorrelation (rho){p_end}
{synopt:{cmd:r(sd)}}specified standard deviation for generating randomness{p_end}
{synopt:{cmd:r(posttrend)}}specified post-intervention trend{p_end}
{synopt:{cmd:r(step)}}specified step (change in level){p_end}
{synopt:{cmd:r(pretrend)}}specified pre-intervention trend{p_end}
{synopt:{cmd:r(intercept)}}specified intercept (starting level of the time series){p_end}
{synopt:{cmd:r(trperiod)}}time period of when the intervention was introduced{p_end}
{synopt:{cmd:r(separator)}}number of lines between separator lines in the table{p_end}
{synopt:{cmd:r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}

{synoptset 17 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}{cmd:single_itsa}{p_end}
{synopt:{cmd:r(columns)}}displayed table columns{p_end}
{synopt:{cmd:r(labels)}}table column labels{p_end}
{synopt:{cmd:r(widths)}}table column widths{p_end}
{synopt:{cmd:r(formats)}}table column formats{p_end}

{synoptset 17 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(pss_table)}}table of results{p_end}
{p2colreset}{...}


{synoptset 17 tabbed}{...}
{pstd} {cmd:Multiple-group ITSA}{p_end}

{p2col 5 14 18 2: Scalars}{p_end}
{synopt:{cmd:r(power)}}power for the computed sample size{p_end}
{synopt:{cmd:r(beta)}}probability of a type II error{p_end}
{synopt:{cmd:r(alpha)}}significance level{p_end}
{synopt:{cmd:r(N)}}computed sample size{p_end}
{synopt:{cmd:r(contcnt)}}the number of control units{p_end}
{synopt:{cmd:r(onesided)}}1 for a one-sided test, 0 otherwise{p_end}
{synopt:{cmd:r(reps)}}the number of repetitions{p_end}
{synopt:{cmd:r(tacorr)}}treated unit's autocorrelation (rho){p_end}
{synopt:{cmd:r(tsd)}}treated unit's standard deviation for generating variability{p_end}
{synopt:{cmd:r(tposttrend)}}treated unit's post-intervention trend{p_end}
{synopt:{cmd:r(tstep)}}treated unit's step (change in level){p_end}
{synopt:{cmd:r(tpretrend)}}treated unit's pre-intervention trend{p_end}
{synopt:{cmd:r(tintercept)}}treated unit's intercept (starting level of the time series){p_end}
{synopt:{cmd:r(cacorr)}}controls' autocorrelation (rho){p_end}
{synopt:{cmd:r(csd)}}controls' standard deviation for generating variability{p_end}
{synopt:{cmd:r(cposttrend)}}controls' post-intervention trend{p_end}
{synopt:{cmd:r(cstep)}}controls' step (change in level){p_end}
{synopt:{cmd:r(cpretrend)}}controls' pre-intervention trend{p_end}
{synopt:{cmd:r(cintercept)}}controls' intercept (starting level of the time series){p_end}
{synopt:{cmd:r(trperiod)}}time period of when the intervention was introduced{p_end}
{synopt:{cmd:r(separator)}}number of lines between separator lines in the table{p_end}
{synopt:{cmd:r(divider)}}1 if divider is requested in the table, 0 otherwise{p_end}

{synoptset 17 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:test}{p_end}
{synopt:{cmd:r(method)}}{cmd:multi_itsa}{p_end}
{synopt:{cmd:r(columns)}}displayed table columns{p_end}
{synopt:{cmd:r(labels)}}table column labels{p_end}
{synopt:{cmd:r(widths)}}table column widths{p_end}
{synopt:{cmd:r(formats)}}table column formats{p_end}

{synoptset 17 tabbed}{...}
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

{phang}
---------. 2025. 
{browse "https://journals.sagepub.com/doi/10.1177/01632787251361514":A comprehensive simulation study to evaluate the effect size and study length relationship in single-group interrupted time series analysis}. 
{it:Evaluation & the Health Professions} 



{marker citation}{title:Citation of {cmd:power itsa}}

{p 4 8 2}{cmd:power itsa} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). POWER ITSA: Stata module to compute power for single and multiple-group interrupted time series analysis. 
Statistical Software Components S459461, Boston College Department of Economics. 
{browse "https://ideas.repec.org/c/boc/bocode/s459461.html":https://ideas.repec.org/c/boc/bocode/s459461.html} 

{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb power}, {helpb simulate}, {helpb itsa} (if installed), {helpb itsadgp} (if installed) {p_end}

