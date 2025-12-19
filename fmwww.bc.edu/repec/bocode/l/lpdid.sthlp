{smcl}


{title:Title}

{pstd}{hi: lpdid} {hline 2} Local Projections Difference-in-Differences (LP-DiD) estimator.


{marker syntax}{...}
{title:Syntax}

{text}{phang2}{cmd:lpdid}
 {depvar} 
 [{it:if}] [{it:in}] [{it:weight}], 
 {opt u:nit}({it:varname}) 
 {opt t:ime}({it:varname}) 
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
Positive integer >=2 required. Either pre_window or post_window needs to be specified. {p_end}
{synopt :{opt post_window}({it:#})} Length of the post-treatment window of the event-study estimates. 
Positive integer >=0 required. 
Either pre_window or post_window needs to be specified. {p_end}

{synoptline}
{syntab:{bf: Additional Diff-in-Diff Options}}
{synopthdr}
{synoptline}
{synopt :{opt cluster}({it:varname}) } Cluster for SEs (default is to use the variable indexing units). {p_end}
{synopt :{opt controls}({it:varlist}) } List of covariates 
(excluding lags of the dependent variable, which can be included using the ylags() or dylags() options described below). 
Note: since version 1.0.1, time-series and other STATA operators are now allowed in the controls() option. {p_end}
{synopt :{opt absorb}({it:varlist}) } Categorical variables that identify additional fixed effects to be absorbed. 
Note 1: Time effects are always automatically included (otherwise it would not be DiD!); 
if you only want to absorb time indicators, there is no need to use this option. 
Note 2: Please remember that unit fixed effects are already filtered out by the differencing of the outcome. 
Therefore, in most cases you will {it:not} want to include unit fixed effects in the LP-DiD specification. 
Adding unit fixed effects to the LP-DiD specification is equivalent to including unit-specific linear time trends.  {p_end}
{synopt :{opt ylags}({it:#})} Lags of the dependent variable to be included as covariates. {p_end}
{synopt :{opt dylags}({it:#})} Lags of first-differenced dependent variable to be included as covariates. {p_end}
{synopt :{opt nonabs:orbing}({it:#, [notyet] [firsttreat] [oneoff]})} Non-absorbing treatment. 
This option is for treatments that can turn on and off (e.g., policies that can be enacted and repealed),
so that units can enter and exit treatment multiple times.
This option requires a numerical or string input of the format “# , [notyet] [firsttreat] [oneoff]”. 
The integer # is the number of periods after which treatment effects are assumed to stabilize.
The [notyet] suboption restricts the control group to not-yet treated units only; 
The [firsttreat] suboption restricts the treatment group to first treatments only. 
The [oneoff] suboption is for shock-type treatments lasting one period (e.g., hurricanes). 
If [oneoff] is selected, the command assumes that treatment lasts only for 1 period by construction, 
although its effects can still be dynamic and persistent,
and a unit can still experience multiple treatment events.
If instead [oneoff] is not selected,
the command assumes that after a unit enters treatment, 
its treatment status persists
(and the treatment indicator stays equal to 1) 
until a possible exit or reversal (e.g., democratization).
See command description and examples below for more details.
{p_end}
{synopt :{opt never:treated}} Only use never treated observations as control units. 
(Default is to use all clean controls, including not-yet treated units and possibly, 
if treatment is non-absorbing, treated units which treatment effects have stabilized.) {p_end}
{synopt :{opt noco:mp}} Rule out composition effects across the post-treatment window. 
It ensures that the set of clean control units is the same across all post-and pre-treatment time horizons. 
Default is to use all available clean controls at each time horizon, which might introduce composition effects. {p_end}
{synopt :{opt rw}} Reweight observations to estimate an equally weighted ATT. 
Default is to not reweigh observations, which yields a variance-weighted ATT with strictly positive weights. {p_end}
{synopt :{opt pmd}({it:#|max})} Pre-mean-differenced version of LP-DiD. 
The option argument indicates how many periods are used to compose the pre-treatment baseline; 
if "max" is selected, all available pre-treatment periods are used; 
if instead of "max" an integer k is specified, pmd uses a moving average over [-k,-1]. 
Default is "max" if absorbing treatment. 
Default is k=L if nonabsorbing treatment, where L is the argument of the nonabsorbing() option, 
unless firsttreat & (notyet | nevertreated) are selected, in which case the default is "max".  {p_end}
{synopt :{opt boot:strap}({it:#})} Wild bootstrap for SEs, argument is the number of repetitions. 
Using wild bootstrap is advisable in settings with few clusters or few treated clusters.{p_end}
{synopt :{opt seed}({it:#})} Set seed for bootstrap. {p_end}
{synopt :{opt post_pooled}({it:#})} Sets the length of the post-treatment window for the pooled estimates. 
Default is [0, post_window], which means using the same post-treatment window as in the event study estimates. 
Users can either specify only one integer as input, which is then used to replace post_window, 
or they can specify two integers to set a custom interval. {p_end}
{synopt :{opt pre_pooled}({it:#})} Sets the length of the pre-treatment window for the pooled estimates. 
Default is [-pre_window -2], which means using the same pre-treatment window as in the event study estimates. 
Users can either specify only one integer as input, which is then used to replace pre_window, 
or they can specify two integers to set a custom interval in the format (pooled_start pooled_end) 
(both positive integers). {p_end}
{synopt :{opt weights}({it:varname})} Weight observations using the weights stored in variable {it:varname}. 
Note 1: if rw is not selected, 
the weights provided are applied on top of the variance-based weights 
(as a standard weighted regression would do); 
if rw is also selected, observations are weighted just based on {it:varname}. 
Note 2: Since version 1.0.1, weights can be applied using the standard STATA syntax [{it:weight}], 
like in the 'regress' command, but this option is still available for backward compatibility.{p_end}

{synoptline}
{syntab:{bf: Reporting Options}}
{synopthdr}
{synoptline}

{synopt :{opt level}({it:#})} Significance level for confidence intervals, default is 95. {p_end}
{synopt :{opt nograph}} If specified, no graphical output. {p_end}
{synopt :{opt only_pooled}} If specified, event study estimates are not computed (increases computational speed). {p_end}
{synopt :{opt only_event}} If specified, pooled estimates are not computed (increases computational speed). {p_end}

{synoptline}

{marker description}{...}
{title:Description}

{pstd}{cmd:lpdid} performs the Local Projections Difference-in-Differences estimator (LP-DiD) 
proposed by {browse "https://doi.org/10.1002/jae.70000":Dube, Girardi, Jordà and Taylor, 2025} (DGJT hereafter). {p_end}

{pstd} LP-DiD is a convenient and flexible regression-based framework for implementing Difference-in-Differences. 
It uses panel data to estimate the average effect of a binary treatment 
under the assumptions of no-anticipation and (conditional) parallel trends. 
It can provide both dynamic event study estimates
and a 'pooled' estimate which gives an overall average effect over the post-treatment window.

{pstd} LP-DiD uses local projections to estimate dynamic effects, 
while restricting the estimation sample to units entering treatment and 'clean' controls, 
thus avoiding the 'negative-weighting' bias of TWFE estimators. 
The baseline version estimates a variance-weighted effect, 
giving more weight to more precisely estimated cohort-specific effects. 
The reweighed version (implemented through the [rw] option) estimates an equally-weighted average effect,
giving equal weight to all treated observations. 
If effects are homogeneous across treated cohorts, variance-weighting is most efficient.
With treatment effects heterogeneity, there is a bias-variance tradeoff: variance-weighting has
some bias because different treated units can receive different weights 
(although weights are always positive, unlike in TWFE)
but has lower variance because it gives more weight to more precisely estimated effects.

{pstd} LP-DiD offers flexibility in comparing post-treatment outcomes to the last pre-treatment period (the default option) 
or to an average of several pre-treatment periods (the pmd() option). 

{pstd} Time-invariant or time-varying covariates can be included using the controls() option.
An advantage of LP-DiD is that, if the lagged value of a time-varying covariate is included,
this is measured pre-treatment (unlike in TWFE specifications).
It is possible to include pre-treatment lags of the outcome as control variables using the ylags() or dylags() options.
It is possible to absorb additional fixed effects (in addition to time effects, always included by default) 
using the absorb() option.

{pstd} Note that if the [rw] option is selected and covariates are included, 
the command implements the Regression Adjustment LP-DiD specification with covariates described in 
{browse "https://doi.org/10.1002/jae.70000":DGJT}, Section 4.1.1.
If covariates are included and the [rw] option is not selected, the command directly includes covariates in a 
OLS LP-DiD specification, which requires the additional assumption that treatment effects do not vary with
covariates, as explained in {browse "https://doi.org/10.1002/jae.70000":DGJT}, 
Section 4.1.2.

{pstd} Treatment can be absorbing (once a unit gets treated, it stays treated) or non-absorbing 
(units can enter and exit treatment multiple times). 
If treatment is non-absorbing, the nonabsorbing() option must be specified,
where the option's argument is the number of post-treatment periods after which treatment effects are assumed to stabilise.

{pstd} By default, nonabsorbing() assumes that you have a 'persistent treatment' setting: 
after a unit enters treatment, its treatment status persists 
(ie, the treatment variable remains equal to 1) until a possible exit or reversal.
An example of this type of treatment is democracy:
after democratization, the country remains a democracy until a possible reversal.
Use the [oneoff] suboption if you have a 'oneoff' (or 'shock') setting, 
in which treatment is by definition confined to a single period.
A typical example of 'oneoff' treatment is hurricanes:
the treatment indicator equals 1 if the unit is hit by a hurricane at time t,
and 0 in all other periods (although effects might still be long-lasting and dynamic,
and the same unit might experience more than one hurricane during the sample period).

{pstd} When using the nonabsorbing() option, if the suboption [firsttreat] is selected 
in combination with either suboption [notyet] or option [nevertreated], 
the command estimates the effect of entering treatment for the first time versus a counterfactual of remaining untreated,
and the numerical argument can be omitted from the nonabsorbing() option.

{pstd} Note that the nonabsorbing() option without the [firsttreat] suboption implements the estimator for the average effect 
of a treatment event under an effect stabilization assumption presented in {browse "https://doi.org/10.1002/jae.70000":DGJT}, 
Section 4.2.3.
The nonabsorbing() option with suboption [firsttreat] and either suboption [notyet] or command option [nevertreated] 
implements the estimator for the effect of entering treatment for the first time relative to a 
counterfactual of remaining untreated presented in {browse "https://doi.org/10.1002/jae.70000":DGJT}, 
Section 4.2.2.

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

{pstd}This program requires the user-written commands {cmd:reghdfe}, {cmd:listreg}, {cmd:boottest}, and the {cmd:egenmore} package. 
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
{stata ssc install boottest, replace}
{p_end}
{p 8 16 2}
{stata ssc install egenmore, replace}
{p_end}

{marker examples}{...}
{title:Example with absorbing treatment}

{p 4 8}Upload simulated dataset with staggered absorbing treatment{p_end}
{p 8 12 2}
    {stata "use http://fmwww.bc.edu/repec/bocode/l/lpdidtestdata1.dta"}
    {p_end}

{p 4 8}Run baseline version of LP-DiD (it estimates a variance-weighted average effect, with strictly positive weights) {p_end}
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

{title:Example with non-absorbing treatment}

{p 4 8}Upload simulated dataset with nonabsorbing treatment{p_end}
{p 8 12 2}
    {stata "use http://fmwww.bc.edu/repec/bocode/l/lpdidtestdata2.dta, clear"}
    {p_end}

{p 4 8}Estimate average (variance-weighted) effect of treatment events, assuming that effects stabilise after 5 periods {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5)}
    {p_end}

{p 4 8}Estimate average effect of treatment events, reweighting for the equally-weighted ATT {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5) rw}
    {p_end}

{p 4 8}Use only non-yet treated as controls {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5, notyet)}
    {p_end}

{p 4 8}Use only non-yet treated as controls and avoid composition effects {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5, notyet) nocomp}
    {p_end}

{p 4 8}Estimate the effect of entering treatment for the first time and staying treated, 
using only not-yet treated units as controls {p_end}
{p 4 8} (Note that in this case there is no need to assume that effects stabilise after # periods, 
	 so the numerical argument can be omitted from the nonabsorbing() option) {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(, firsttreat notyet)}
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
using only non-yet treated units as controls {p_end}
{p 4 8} (Note that in this case there is no need to assume that effect stabilise after # periods, 
	 so the integer can be omitted from the nonabsorbing() option} {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(, firsttreat notyet oneoff)}
    {p_end}

{p 4 8} Estimate the effect of receiving treatment for the first time, 
using only never treated units as controls {p_end}
{p 4 8} (Note that in this case there is no need to assume that effects stabilise after # periods, 
	 so the numerical argument can be omitted from the nonabsorbing() option} {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(, firsttreat oneoff) nevertreated}
    {p_end}

{marker results}{...}
{title:Stored Results}

{cmd:lpdid} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Macros}{p_end}

{synopt :{cmd:e(results)}} Event study estimates, with coefficients, standard errors, t-values, 
p-value, confidence interval (low), confidence interval (high), observation number {p_end}
{synopt :{cmd:e(pooled_results)}} Pooled estimates, with coefficients, standard errors, t-values, 
p-value, confidence interval (low), confidence interval (high), observation number {p_end}

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}

{synopt :{cmd:e(cmd)}} lpdid {p_end}
{synopt :{cmd:e(cmdline)}} full command line with options selected {p_end}
{synopt :{cmd:e(depvar)}} name of dependent variable {p_end}
{synopt :{cmd:e(controls)}} name(s) of control variable(s) {p_end}
{synopt :{cmd:e(absorb)}} name(s) of categorical variable(s) that identify additional fixed effects to be absorbed {p_end}
{synopt :{cmd:e(ylags)}} number of lags of the dependent variable used on the rhs {p_end}
{synopt :{cmd:e(dylags)}} number of first-differenced lags of the dependent variable used on the rhs {p_end}
{synopt :{cmd:e(pre_window)}} number of pre periods {p_end}
{synopt :{cmd:e(post_window)}} number of post periods {p_end}
{synopt :{cmd:e(control_group)}} definition of control group used {p_end}
{synopt :{cmd:e(treated_group)}} definition of treated group used {p_end}

{title:Accessing Results}

{pstd}
After running lpdid, access results using:

{phang2}{cmd:. matrix list e(results)}{space 10}// Event study coefficients{p_end}
{phang2}{cmd:. matrix list e(pooled_results)}{space 3}// Pooled pre/post effects{p_end}

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
{browse "mailto:busch@mit.edu":abusch@mit.edu}{p_end}

{pstd}
Daniele Girardi {break}
King's College London (UK) {break}
{browse "mailto:daniele.girardi@kcl.ac.uk":daniele.girardi@kcl.ac.uk}{p_end}

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
