{smcl}

{* *! version 1.1.0  Sep2026}{...}
{viewerjumpto "Syntax" "lpdid##syntax"}{...}
{viewerjumpto "Quick Start" "lpdid##quickstart"}{...}
{viewerjumpto "Options" "lpdid##options"}{...}
{viewerjumpto "Description" "lpdid##description"}{...}
{viewerjumpto "Dependencies" "lpdid##dependencies"}{...}
{viewerjumpto "Examples" "lpdid##examples"}{...}
{viewerjumpto "Stored results" "lpdid##results"}{...}
{viewerjumpto "Accessing results" "lpdid##accessing"}{...}
{viewerjumpto "Example of plotting results" "lpdid##plotting"}{...}
{viewerjumpto "Authors" "lpdid##authors"}{...}
{viewerjumpto "Acknowledgements" "lpdid##acknowledgements"}{...}

{title:Title}

{pstd}{hi: lpdid} {hline 2} Local Projections Difference-in-Differences (LP-DiD) estimator.


{marker syntax}{...}
{title:Syntax}

{text}{phang2}{cmd:lpdid}
 {depvar} 
 [{it:if}] [{it:in}] [{it:weight}], 
 {opt unit}({it:varname}) 
 {opt time}({it:varname}) 
 {opt treat}({it:varname}) 
 {opt pre:_window}({it:integer}) 
 {opt post:_window}({it:integer}) 
 [{it:options}]{p_end}

{marker quickstart}{...}
{title:Quick Start}

{pstd}
Basic LP-DiD specification with staggered treatment:

{p 8 16 2}
{cmd:lpdid Y, unit(state) time(year) treat(policy) pre(10) post(10)}

{pstd}
Same specification but reweighted to estimate an equally-weighted ATT instead of a variance-weighted ATT:

{p 8 16 2}
{cmd:lpdid Y, unit(state) time(year) treat(policy) pre(10) post(10) rw}

{pstd}
Reweighted and with controls:

{p 8 16 2}
{cmd:lpdid Y, unit(state) time(year) treat(policy) pre(10) post(10) rw controls(gdp unemployment)}

{pstd}
Non-absorbing treatment (e.g., policies that can be reversed), assuming that effects stabilise after 5 periods:

{p 8 16 2}
{cmd:lpdid Y, unit(state) time(year) treat(policy) pre(10) post(10) nonabsorbing(5)}

{pstd}
Reweighted and with aggregate average effect over the post-treatment window:

{p 8 16 2}
{cmd:lpdid Y, unit(state) time(year) treat(policy) pre(10) post(10) rw aggregate_average}

{pstd}
With pooled LP-DiD estimate for the overall effect (since version 1.1.0 provided only on request):

{p 8 16 2}
{cmd:lpdid Y, unit(state) time(year) treat(policy) pre(10) post(10) pooled}

{pstd}
With a pre-trend test (joint test of the null that all pre-treatment coefficients are zero):

{p 8 16 2}
{cmd:lpdid Y, unit(state) time(year) treat(policy) pre(10) post(10) pretrend_test}

{pstd}
For more detailed examples using a simulated dataset, see {help lpdid##examples:Examples} below.

{marker options}{...}
{title:Options}

{synoptset 20 tabbed}{...}

{syntab:{bf: Main Parameters}}
{synopthdr}
{synoptline}
{synopt :{opt unit}({it:varname}) } Variable indexing units of observation. 
(Also cluster unit for SEs, unless otherwise selected by the user.) {p_end}
{synopt :{opt time}({it:varname}) } Variable indexing time periods (or time-equivalent). {p_end}
{synopt :{opt treat}({it:varname}) } Treatment indicator 
(Note: the command only supports binary treatments.) {p_end}
{synopt :{opt pre_window}({it:#})} Length of the pre-treatment window of the event-study estimates. 
Positive integer >=2 required. 
Either {opt pre_window()} or {opt post_window()} needs to be specified. {p_end}
{synopt :{opt post_window}({it:#})} Length of the post-treatment window of the event-study estimates. 
Positive integer >=0 required. 
Either {opt pre_window()} or {opt post_window()} needs to be specified. {p_end}

{synoptline}
{syntab:{bf: Additional Diff-in-Diff Options}}
{synopthdr}
{synoptline}
{synopt :{opt cluster}({it:varname}) } Cluster for SEs (default is to use the variable indexing units). {p_end}
{synopt :{opt rw}} Reweight observations to estimate an equally weighted ATT. 
Default is to not reweigh observations, which yields a variance-weighted ATT with strictly positive weights. {p_end}
{synopt :{opt controls}({it:varlist}) } List of covariates.
Note: since version 1.0.1, time-series and other STATA operators are now allowed in the {opt controls()} option. {p_end}
{synopt :{opt ylags}({it:#})} Lags of the dependent variable to be included as covariates. {p_end}
{synopt :{opt dylags}({it:#})} Lags of first-differenced dependent variable to be included as covariates. {p_end}
{synopt :{opt absorb}({it:varlist}) } Categorical variables that identify additional fixed effects to be absorbed. 
Note 1: Time effects are always automatically included (otherwise it would not be DiD!); 
if you only want to absorb time indicators, there is no need to use this option. 
Note 2: Please remember that unit fixed effects are already filtered out by the differencing of the outcome. 
Therefore, in most cases you will {it:not} want to include unit fixed effects in the LP-DiD specification. 
Adding unit fixed effects to the LP-DiD specification is equivalent to including unit-specific linear time trends.  {p_end}
{synopt :{opt nonabs:orbing}({it:#, [notyet] [firsttreat] [oneoff]})} Non-absorbing treatment. 
This option is for treatments that can turn on and off (e.g., policies that can be enacted and repealed),
so that units can enter and exit treatment multiple times.
This option requires a numerical or string input of the format “# , [notyet] [firsttreat] [oneoff]”. 
The integer # is the number of periods after which treatment effects are assumed to stabilize.
The {opt notyet} suboption restricts the control group to not-yet treated units only; 
The {opt firsttreat} suboption restricts the treatment group to first treatments only. 
The {opt oneoff} suboption is for shock-type treatments lasting one period (e.g., hurricanes). 
If {opt oneoff} is selected, the command assumes that treatment lasts only for 1 period by construction, 
although its effects can still be dynamic and persistent,
and a unit can still experience multiple treatment events.
If instead {opt oneoff} is not selected,
the command assumes that after a unit enters treatment, 
its treatment status persists
(and the treatment indicator stays equal to 1) 
until a possible exit or reversal (e.g., democratization).
See {help lpdid##description:Description} and {help lpdid##examples:Examples} below for more details.
{p_end}
{synopt :{opt never:treated}} Only use never treated observations as control units. 
(Default is to use all clean controls, including not-yet treated units and possibly, 
if treatment is non-absorbing, treated units which treatment effects have stabilized.) {p_end}
{synopt :{opt noco:mp}} Rule out composition effects across the event window. 
It ensures that the set of contributing observations is the same across every post- and pre-treatment
horizon in the window.
Default is to use all available and admissible observations at each time horizon, 
which might introduce composition effects. 
Note that holding the estimation sample fixed across horizons,
as done by the {opt nocomp} option, 
can substantially reduce sample size in some settings. {p_end}
{synopt :{opt untreated_:before}} Assume that every unit is untreated before it enters the panel.
The default is not to make this assumption, 
and hence to consider an observation clean only if all the treatment values 
in the relevant window are observed and verifiable.
This option is relevant only if {opt nonabsorbing()} is specified, 
because only in that setting might the command need to look back over a window of past treatment values 
to evaluate a clean control condition or (if {opt pmd} is selected) to compute the pre-mean differenced (PMD) baseline.
Note that, as a logical consequence, 
a unit already treated in the period when it enters the panel is assumed to have entered treatment in that period, 
which might cause nearby observations for that unit to remain excluded from the estimation sample.{p_end}
{synopt :{opt pmd}({it:#|max})} Pre-mean-differenced (PMD) version of LP-DiD. 
The option argument indicates how many periods are used to compose the pre-treatment baseline; 
if "max" is selected, all available pre-treatment periods are used; 
if instead of "max" an integer k is specified, {opt pmd()} uses a moving average over [-k,-1]. 
Default is "max" if absorbing treatment. 
Default is k=L if nonabsorbing treatment, where L is the argument of the {opt nonabsorbing()} option,
unless {opt firsttreat} & ({opt notyet} | {opt nevertreated}) are selected, 
in which case the default is "max".  
Note 1: {opt pmd()} with an integer requires the whole window: 
an observation whose outcome is missing at any of the {it:k} lags gets no baseline and drops out. 
With "max", instead, the baseline is the mean of whatever pre-treatment
outcomes are observed.
Note 2: the PMD baseline is computed before any {it:if} or {it:in} restriction is applied, 
so it can draw on periods the restriction excludes.
To avoid that, 
you can drop the unwanted observations before calling {cmd:lpdid}
rather than restricting the sample with {it:if} or {it:in}.
{p_end}
{synopt :{opt boot:strap}({it:#})} Wild bootstrap for SEs, argument is the number of repetitions. 
Using wild bootstrap is advisable in settings with few clusters or few treated clusters.
Note: with {opt rw} and {opt controls()}, a control that combines a time-series operator
with an interaction (eg, {cmd:L.bin1#i.cat}) or a numlist operator (eg, {cmd:L(1/2).xc})
is not supported under {opt bootstrap()}, and the estimates are returned as missing.
The same specifications estimate normally without {opt bootstrap()}.
Creating the transformed variable first avoids this problem (eg, {cmd:controls(Lxc)});
inside an interaction it must also carry an explicit {cmd:i.} prefix 
(eg, {cmd:controls(i.Lbin1#i.cat)}).
A factor variable entered with {cmd:ibn.} notation (eg, {cmd:controls(ibn.cat)}) fails differently:
the coefficients are returned, 
but the wild bootstrap yields no test statistic, 
p-value or confidence interval. 
Specifying a base category (eg, {cmd:controls(i.cat)}) avoids this.{p_end}
{synopt :{opt seed}({it:#})} Set seed for bootstrap. {p_end}
{synopt :{opt post_pooled}({it:#})} Sets the length of the post-treatment window for the pooled estimates.
Implies the {opt pooled} option (see below).
Default is [0, post_window], which means using the same post-treatment window as in the event study estimates. 
Users can either specify only one integer as input, which is then used to replace {opt post_window()}, 
or they can specify two integers to set a custom interval. {p_end}
{synopt :{opt pre_pooled}({it:#})} Sets the length of the pre-treatment window for the pooled estimates.
Implies the {opt pooled} option (see below).
Default is [-pre_window -2], which means using the same pre-treatment window as in the event study estimates. 
Users can either specify only one integer as input, which is then used to replace {opt pre_window()}, 
or they can specify two integers to set a custom interval in the format (pooled_start pooled_end) 
(both positive integers). 
Note: If {opt pmd()} is selected, the pre-treatment pooled estimate can become hard to interpret,
because it can compare two overlapping averages of pre-treatment observations.
(This does not apply to the event study coefficients or to {opt pretrend_test}.)
{p_end}
{synopt :{opt weights}({it:varname})} Weight observations using the weights stored in variable {it:varname}. 
Note 1: if {opt rw} is not selected, 
the weights provided are applied on top of the variance-based weights 
(as a standard weighted regression would do); 
if {opt rw} is also selected, observations are weighted just based on {it:varname}. 
Note 2: Since version 1.0.1, weights can be applied using the standard STATA syntax [{it:weight}], 
like in the 'regress' command, but this option is still available for backward compatibility.{p_end}

{synoptline}
{syntab:{bf: Reporting Options}}
{synopthdr}
{synoptline}

{synopt :{opt level}({it:#})} Significance level for confidence intervals, default is 95. {p_end}
{synopt :{opt nograph}} If specified, no graphical output. {p_end}
{synopt :{opt agg:regate_average}} Report the observation-weighted average of the event study estimates,
for the post-treatment window and for the pre-treatment window,
each with a standard error, a confidence interval and a p-value.
(Under {opt bootstrap()}, however, 
wild bootstrap is used for inference and no standard error is reported.)
The weights are the numbers of treated observations in each horizon.
This provides an estimate of the overall average effect across all treated observations
in the post-treatment window:
with {opt rw} the ATT; 
without {opt rw} the variance-weighted counterpart (VWATT). 
Its standard error is computed from influence functions,
and its p-value and confidence interval employ a t(M-1) statistic,
with M the number of clusters in the estimation sample.
If {opt bootstrap()} is selected, p-value and confidence interval are obtained
by applying wild bootstrap on a stacked regression.
Requires {opt post_window()}. {p_end}
{synopt :{opt pretrend_:test}} Report a joint test of the null hypothesis 
that all pre-treatment coefficients are zero.
Requires {opt pre_window()}.
Employs a F(P, M-1) statistics, where P is the number of pre-treatment coefficients tested
and M is the number of clusters in the estimation sample.
Under {opt bootstrap()} the test is computed by wild bootstrap instead.
Note: A pre-treatment horizon with no usable estimate is excluded from the test and named beneath it,
as is any horizon that is zero by construction
(for example because {opt ylags()} or {opt dylags()} was specified).
The test is then a joint test on the remaining horizons.
Not available when {opt bootstrap()} is combined with {opt rw} and {opt controls()}, 
{opt ylags()} or {opt dylags()}. {p_end}
{synopt :{opt pooled}} Compute and report the pooled LP-DiD estimates.
It gives an overall average effect over the pooled post-treatment window
and the corresponding average over the pooled pre-treatment window.
With {opt rw} it estimates the ATT across all treated units with a complete post- (or pre-)treatment window;
without {opt rw} the variance-weighted counterpart (VWATT).
Default is not to compute them.
This option is implied by {opt only_pooled}, {opt pre_pooled()} and {opt post_pooled()},
each of which requires the pooled estimate.
It is overridden by {opt only_event}, which suppresses the pooled estimates whatever else is specified.
Note: this is a change from version 1.0.3 and earlier, which reported the pooled estimates by default. 
Note 2: see {help lpdid##description:Description} below for the difference between 
{opt aggregate_average} and {opt pooled}. {p_end}
{synopt :{opt only_pooled}} If specified, event study estimates are not reported. 
Implies the {opt pooled} option (see above).
This can save computing time when only the {opt pooled} estimates are of interest.
The event study horizons, 
however, 
still need to be estimated if {opt aggregate_average} or {opt pretrend_test} is requested. {p_end}
{synopt :{opt only_event}} Retained for backward compatibility. 
It suppresses the pooled estimates. 
This option was relevant in version 1.0.3 and earlier, 
when the pooled estimates were computed and reported by default. {p_end}

{synoptline}

{marker description}{...}
{title:Description}

{pstd}{cmd:lpdid} performs the Local Projections Difference-in-Differences estimator (LP-DiD) 
proposed by {browse "https://doi.org/10.1002/jae.70000":Dube, Girardi, Jordà and Taylor, 2025} 
(DGJT hereafter). {p_end}

{pstd} LP-DiD is a convenient and flexible regression-based framework for implementing Difference-in-Differences. 
It uses panel data to estimate the average effect of a binary treatment 
under the assumptions of no-anticipation and (conditional) parallel trends. 
By default it provides dynamic event study estimates.
It can also report an overall average effect over the post-treatment window,
for which two alternative estimators are available
through the {opt aggregate_average} and {opt pooled} options.

{pstd} LP-DiD uses local projections to estimate dynamic effects, 
while restricting the estimation sample to units entering treatment and 'clean' controls, 
thus avoiding the 'negative-weighting' bias of TWFE estimators. 
The baseline version estimates a variance-weighted effect, 
giving more weight to more precisely estimated cohort-specific effects. 
The reweighed version (implemented through the {opt rw} option) estimates an equally-weighted average effect,
giving equal weight to all treated observations. 
If effects are homogeneous across treated cohorts, variance-weighting is most efficient.
With treatment effects heterogeneity, there is a bias-variance tradeoff: variance-weighting has
some bias because different treated units can receive different weights 
(although weights are always positive, unlike in TWFE)
but has lower variance because it gives more weight to more precisely estimated effects.

{pstd} LP-DiD offers flexibility in comparing post-treatment outcomes to the last pre-treatment period (the default option) 
or to an average of several pre-treatment periods (the {opt pmd()} option). 

{pstd} Time-invariant or time-varying covariates can be included using the {opt controls()} option.
An advantage of LP-DiD is that, if the lagged value of a time-varying covariate is included,
this is measured pre-treatment (unlike in TWFE specifications).
It is possible to include pre-treatment lags of the outcome as control variables 
using the {opt ylags()} or {opt dylags()} options, 
or directly using time-series operators in the {opt controls()} option.
It is possible to absorb additional fixed effects (in addition to time effects, always included by default) 
using the {opt absorb()} option.

{pstd} If the {opt rw} option is selected and covariates are included, 
the command implements the Regression Adjustment LP-DiD specification with covariates described in 
{browse "https://doi.org/10.1002/jae.70000":DGJT}, Section 4.1.1.
If covariates are included and the {opt rw} option is not selected, the command directly includes covariates in a 
OLS LP-DiD specification, which requires the additional assumption that treatment effects do not vary with
covariates, as explained in {browse "https://doi.org/10.1002/jae.70000":DGJT}, 
Section 4.1.2.

{pstd} Treatment can be absorbing (once a unit gets treated, it stays treated) or non-absorbing 
(units can enter and exit treatment multiple times). 
If treatment is non-absorbing, the {opt nonabsorbing()} option must be specified,
where the option's argument is the number of post-treatment periods after which treatment effects are assumed to stabilise.

{pstd} By default, {opt nonabsorbing()} assumes that you have a 'persistent treatment' setting: 
after a unit enters treatment, its treatment status persists 
(ie, the treatment variable remains equal to 1) until a possible exit or reversal.
An example of this type of treatment is democracy:
after democratization, the country remains a democracy until a possible reversal.
Use the {opt oneoff} suboption if you have a 'oneoff' (or 'shock') setting, 
in which treatment is by definition confined to a single period.
A typical example of 'oneoff' treatment is hurricanes:
the treatment indicator equals 1 if the unit is hit by a hurricane at time t,
and 0 in all other periods (although effects might still be long-lasting and dynamic,
and the same unit might experience more than one hurricane during the sample period).

{pstd} The {opt nonabsorbing()} option without the {opt firsttreat} suboption
implements the estimator for the average effect of a treatment event under an effect
stabilization assumption presented in {browse "https://doi.org/10.1002/jae.70000":DGJT},
Section 4.2.3.
With the {opt firsttreat} suboption, in combination with either the {opt notyet} suboption
or the {opt nevertreated} option, it instead implements the estimator for the effect of entering
treatment for the first time relative to a counterfactual of remaining untreated, presented in
{browse "https://doi.org/10.1002/jae.70000":DGJT}, Section 4.2.2;
in that case the numerical argument can be omitted from the {opt nonabsorbing()} option.

{pstd} The options {opt aggregate_average} and {opt pooled} offer two alternative estimators 
of the overall average effect in the post-treatment window
(and a corresponding estimate over the pre-treatment window).
{opt aggregate_average} averages the event study coefficients,
weighting each horizon by the number of treated observations behind it.
It therefore estimates the overall average effect
across all treated observations in the post-treatment window.
{opt pooled} instead implements the pooled LP-DiD estimator described
in Section 3.5 of {browse "https://doi.org/10.1002/jae.70000":DGJT}.
It runs a single regression on the outcome 
averaged over the post- (or pre-)treatment window,
which requires that window to be complete.
It therefore estimates the average effect among units observed in the entire window.

{pstd} The main difference between {opt aggregate_average}
and {opt pooled}, therefore, 
is that {opt pooled} holds the set of contributing units fixed across horizons
(no composition effects),
but at the cost of excluding observations with incomplete windows.
The pooled estimate is therefore the more data-demanding of the two.
In some settings the two rest on the same events at every horizon,
and provide identical estimates.
For example this occurs if {opt nocomp} is selected
(so the underlying event study estimates averaged by {opt aggregate_average}
admit no composition effects) and there are no missing values,
nor events whose window is cut short by either end of the panel.
Both {opt aggregate_average} and {opt pooled} follow the {opt rw} option: 
with {opt rw} each targets the equally-weighted ATT,
without it the variance-weighted counterpart (VWATT).

{pstd} While this command attempts to cover the most common settings and target estimands,
there might be applications that require bespoke adjustment not covered here
(for example, an alternative definition of the 'clean control condition'). 
In these cases, you can implement the LP-DiD estimator "manually", 
in the sense of writing your own STATA code for implementing LP-DiD. 
"Manually" implementing LP-DiD is easy, because the method essentially consists in estimating a 
simple regression (or a regression-adjustment specification) in an estimation sample defined by a 
'clean control' condition.
Example codes illustrating how to implement LP-DiD "manually"
can be found {browse "https://github.com/danielegirardi/lpdid":here}.

{pstd} See {browse "https://doi.org/10.1002/jae.70000":DGJT} for a detailed exposition of the LP-DiD method. {p_end}

{marker dependencies}{...}
{title:Dependencies}

{pstd}This program requires the user-written commands {cmd:reghdfe}, {cmd:listreg} and {cmd:boottest} 
(plus {cmd:ftools} and {cmd:require}, which {cmd:reghdfe} needs). 
Please ensure you have the latest versions installed before use. 
You can install them by typing: {p_end}

{p 8 16 2}
{stata ssc install reghdfe, replace}
{p_end}
{p 8 16 2}
{stata ssc install listreg, replace}
{p_end}
{p 8 16 2}
{stata ssc install ftools, replace} // required for reghdfe to work properly
{p_end}
{p 8 16 2}
{stata ssc install require, replace} // required for reghdfe to work properly
{p_end}
{p 8 16 2}
{stata ssc install boottest, replace}
{p_end}

{marker examples}{...}
{title:Example with absorbing treatment}

{p 4 8}Upload simulated dataset with staggered absorbing treatment{p_end}
{p 8 12 2}
    {stata "use http://fmwww.bc.edu/repec/bocode/l/lpdidtestdata1.dta"}
    {p_end}

{p 4 8}Run baseline version of LP-DiD 
(it estimates a variance-weighted average effect, with strictly positive weights) {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10)}
    {p_end}

{p 4 8}Run reweighted LP-DiD (estimates an equally-weighted average effect) {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) rw}
    {p_end}

{p 4 8}Run reweighted LP-DiD, avoiding composition effects{p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) rw nocomp}
    {p_end}

{p 4 8}Run reweighted LP-DiD, avoiding composition effects and using only the never treated as controls {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) rw nocomp nevertreated}
    {p_end}

{p 4 8}Run the PMD (pre-mean differenced) version {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) pmd(max)}
    {p_end}

{p 4 8}Reweighted and with aggregate average effect across the post- (and pre-)treatment window {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) rw aggregate_average}
    {p_end}

{p 4 8}Report the pooled estimates (since version 1.1.0 not provided by default but only on request) {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) pooled}
    {p_end}

{p 4 8}Pool over a narrower post-treatment window than the event study uses {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) pooled post_pooled(0 4)}
    {p_end}

{p 4 8} With pre-trend test (test jointly whether all pre-treatment coefficients are zero) {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) pretrend_test}
    {p_end}

{p 4 8}Both aggregate ATT estimators and the pre-trend test together {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) rw aggregate_average pooled pretrend_test}
    {p_end}

{title:Example with non-absorbing treatment}

{p 4 8}Upload simulated dataset with nonabsorbing treatment{p_end}
{p 8 12 2}
    {stata "use http://fmwww.bc.edu/repec/bocode/l/lpdidtestdata2.dta, clear"}
    {p_end}

{p 4 8}Estimate average (variance-weighted) effect of treatment events, 
assuming that effects stabilise after 5 periods {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5)}
    {p_end}

{p 4 8}Estimate average effect of treatment events, 
reweighting for the equally-weighted ATT {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5) rw}
    {p_end}

{p 4 8}Use only not-yet treated as controls {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5, notyet)}
    {p_end}

{p 4 8}Use only not-yet treated as controls and avoid composition effects {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5, notyet) nocomp}
    {p_end}

{p 4 8}Estimate the effect of entering treatment for the first time and staying treated, 
using only not-yet treated units as controls {p_end}
{p 4 8} (In this case there is no need to assume that effects stabilise after # periods, 
	 so the numerical argument can be omitted from the {opt nonabsorbing()} option) {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(, firsttreat notyet)}
    {p_end}

{p 4 8}Assume units are untreated before they enter the panel, 
admitting observations whose earlier treatment cannot be directly verified {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5) untreated_before}
    {p_end}

{p 4 8}With overall aggregate effect and pre-trend test {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5) rw aggregate_average pretrend_test}
    {p_end}

{title:Example with non-absorbing and one-off treatment}

{p 4 8}Upload simulated dataset with nonabsorbing and oneoff treatment{p_end}
{p 8 12 2}
    {stata "use http://fmwww.bc.edu/repec/bocode/l/lpdidtestdata3.dta, clear"}
    {p_end}

{p 4 8}Estimate average (variance-weighted) effect of treatment events, assuming that effects stabilise after 3 periods {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(3, oneoff)}
    {p_end}

{p 4 8}Estimate average effect of treatment events, reweighting for the equally-weighted ATT {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(3, oneoff) rw}
    {p_end}

{p 4 8} Estimate the effect of receiving treatment for the first time, 
using only not-yet treated units as controls {p_end}
{p 4 8} (In this case there is no need to assume that effects stabilise after # periods, 
	 so the integer can be omitted from the {opt nonabsorbing()} option) {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(, firsttreat notyet oneoff)}
    {p_end}

{p 4 8} Estimate the effect of receiving treatment for the first time, 
using only never treated units as controls {p_end}
{p 4 8} (In this case there is no need to assume that effects stabilise after # periods, 
	 so the numerical argument can be omitted from the {opt nonabsorbing()} option) {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(, firsttreat oneoff) nevertreated}
    {p_end}

{marker results}{...}
{title:Stored results}

{cmd:lpdid} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}

{synopt :{cmd:e(pre_window)}} number of pre periods {p_end}
{synopt :{cmd:e(post_window)}} number of post periods {p_end}
{synopt :{cmd:e(pretrend_F)}} pre-trend test statistic (only if {opt pretrend_test} specified) {p_end}
{synopt :{cmd:e(pretrend_df)}} numerator degrees of freedom of the pre-trend test,
ie the number of pre-treatment coefficients tested {p_end}
{synopt :{cmd:e(pretrend_df_r)}} denominator degrees of freedom of the pre-trend test,
ie clusters minus one {p_end}
{synopt :{cmd:e(pretrend_p)}} p-value of the pre-trend test {p_end}
{synopt :{cmd:e(ylags)}} number of lags of the dependent variable used on the rhs
(only if {opt ylags()} specified) {p_end}
{synopt :{cmd:e(dylags)}} number of first-differenced lags of the dependent variable used on the rhs
(only if {opt dylags()} specified) {p_end}

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Macros}{p_end}

{synopt :{cmd:e(lpdid)}} {cmd:lpdid}, the identifier of the estimation command {p_end}
{synopt :{cmd:e(cmdline)}} full command line with options selected {p_end}
{synopt :{cmd:e(depvar)}} name of dependent variable {p_end}
{synopt :{cmd:e(controls)}} name(s) of control variable(s) (only if {opt controls()} specified) {p_end}
{synopt :{cmd:e(absorb)}} name(s) of categorical variable(s) that identify additional fixed effects to be absorbed 
(only if {opt absorb()} specified) {p_end}
{synopt :{cmd:e(control_group)}} definition of control group used {p_end}
{synopt :{cmd:e(treated_group)}} definition of treated group used {p_end}

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Matrices}{p_end}

{synopt :{cmd:e(results)}} Event study estimates, with coefficients, standard errors, test statistics,
p-value, confidence interval (low), confidence interval (high), observation number.
Not returned if {opt only_pooled} is specified {p_end}
{synopt :{cmd:e(aggregate)}} Aggregate average estimates, in the same seven columns,
one row per window. Only if {opt aggregate_average} is specified {p_end}
{synopt :{cmd:e(pooled_results)}} Pooled estimates, in the same seven columns.
Only if the pooled estimates were requested (see the {opt pooled} option) {p_end}

{pstd}
Note that the last (observations) column has a different meaning in {cmd:e(aggregate)} than in the other two
matrices: there it counts the treated observations behind the average,
whereas in {cmd:e(results)} and {cmd:e(pooled_results)} it is the number of observations
in the regression, including treated and control units. {p_end}

{marker accessing}{...}
{title:Accessing results}

{pstd}
After running lpdid, access results using:

{phang2}{cmd:. matrix list e(results)}{space 10}// Event study coefficients{p_end}

{pstd}
The pooled and aggregate estimates are returned only when requested:

{phang2}{cmd:. lpdid y, unit(id) time(t) treat(d) pre(5) post(5) pooled aggregate_average}{p_end}
{phang2}{cmd:. matrix list e(aggregate)}{space 8}// Aggregate average, post and pre{p_end}
{phang2}{cmd:. matrix list e(pooled_results)}{space 3}// Pooled pre/post effects{p_end}

{marker plotting}{...}
{title:Example of Plotting Results}

{pstd}
This example shows how to create a customized event-study plot after running {cmd:lpdid}.
{p_end}
{p 8 12 2}
    {stata "use http://fmwww.bc.edu/repec/bocode/l/lpdidtestdata1.dta, clear"}
    {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nograph}
    {p_end}
{p 8 12 2}
    {stata matrix R = e(results)}
    {p_end}
{p 8 12 2}
    {stata svmat R, names(col)}
    {p_end}
{p 8 12 2}
    {stata gen horizon = _n - (e(pre_window) + 1) if (_n - (e(pre_window) + 1))<=e(post_window)}
    {p_end}
{p 8 12 2}
    {stata twoway (rcap ci_high ci_low horizon, color(gs6)) (scatter coefficient horizon, color(blue)), legend(off)}
    {p_end}

{marker authors}{...}
{title:Authors}

{pstd}
Alexander Busch{break}
Massachusetts Institute of Technology (USA) {break}
{browse "mailto:abusch@mit.edu":abusch@mit.edu}{p_end}

{pstd}
Daniele Girardi {break}
King's College London (UK) {break}
{browse "mailto:daniele.girardi@kcl.ac.uk":daniele.girardi@kcl.ac.uk}{p_end}

{pstd}Versions 1.0.0 through 1.0.2 were written by both authors; 
versions 1.0.3 and 1.1.0 were written by Daniele Girardi.

{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}We are grateful to Enrique Pinzon (StataCorp), Arin Dube, Liss Hall, Òscar Jordà and Alan M. Taylor{p_end}

{pstd}If you use this package, please cite both the package and the paper introducing the LP-DiD method:{p_end}

{phang2}Busch A. and D. Girardi. 2023. 
{browse "https://ideas.repec.org/c/boc/bocode/s459273.html":"LPDID : Stata module implementing Local Projections Difference-in-Differences (LP-DiD)."}
{it:Statistical Software Components} S459273, Boston College Department of Economics.{p_end}

{phang2}and

{phang2}Dube, A., D. Girardi, Ò. Jordà and A. M. Taylor. 2025. 
{browse "https://doi.org/10.1002/jae.70000":"A Local Projections Approach to Difference-in-Differences."}
{it:Journal of Applied Econometrics}.{p_end}
