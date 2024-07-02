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

{marker options}{...}
{title:Options}

{synoptset 20 tabbed}{...}

{syntab:{bf: Main Parameters}}
{synopthdr}
{synoptline}
{synopt :{opt unit}({it:varname}) } Variable indexing units of observation. 
(Also cluster unit for SEs, unless otherwise selected by the user). {p_end}
{synopt :{opt time}({it:varname}) } Variable indexing time periods (or time-equivalent). {p_end}
{synopt :{opt treat}({it:varname}) } Treatment indicator 
(Note: we currently only support binary treatments, although continuous treatments are potentially possible with local projections diff-in-diff). {p_end}
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
{synopt :{opt nonabs:orbing}({it:#, [notyet] [firsttreat]})} Non-absorbing treatment. 
This option requires a numerical or string input of the format “# , [notyet] [firsttreat]”. 
The integer # is the post-treatment horizon at which effects are assumed to stabilize. 
The [notyet] suboption restricts the control group to not-yet treated units only; 
[firsttreat] restricts the treatment group to first treatments only. {p_end}
{synopt :{opt never:treated}} Only use never treated observations as control units. 
(Default is to use all clean controls, including not-yet treated units and possibly, 
if treatment is non-absorbing, treated units which treatment effects have stabilized.) {p_end}
{synopt :{opt noco:mp}} Rule out composition effects across the post-treatment window. 
It ensures that the set of clean control units is the same across all post-and pre-treatment time horizons. 
Default is to use all available clean controls at each time horizon, which might introduce composition effects. {p_end}
{synopt :{opt rw}} Reweight observations to estimate an equally weighted ATE. 
Default is to not reweigh observations, which yields a variance-weighted ATE with strictly positive weights. {p_end}
{synopt :{opt pmd}({it:#|max})} Pre-mean-differenced version of LP-DiD. 
The option argument indicates how many periods are used to compose the pre-treatment baseline; 
if "max" is selected, all available pre-treatment periods are used; 
if instead of "max" an integer k is specified, pmd uses a moving average over [-k,-1]. 
Default is "max" if absorbing treatment. 
Default is k=L if nonabsorbing treatment, where L is the argument of the nonabsorbing() option, 
unless firsttreat & (notyet | nevertreated) are selected, in which case the default is "max".  {p_end}
{synopt :{opt boot:strap}({it:#})} Wild bootstrap for SE, argument is the number of repetitions. {p_end}
{synopt :{opt seed}({it:#})} Set seed for bootstrap. {p_end}
{synopt :{opt post_pooled}({it:#})} Sets the length of the post-treatment window for the pooled estimates. 
Default is [0, post_window], which means using the same post-treatment window as in the event study estimates. 
Users can either specify only one integer as input, which is then used to replace post_window, 
or they can specify two integers to set a custom interval. {p_end}
{synopt :{opt pre_pooled}({it:#})} Sets the length of the pre-treatment window for the pooled estimates. 
Default is [-pre_window -2], which means using the same pre-treatment window as in the event study estimates. 
Users can either specify only one integer as input, which is then used to replace pre_window, 
or they can specify two integers to set a custom interval in the format (pooled_start pooled_end) (both positive integers). {p_end}
{synopt :{opt weights}({it:varname})} Weight observations using the weights stored in variable {it:varname}. 
Note 1: if rw is not selected, the weights provided are applied on top of the variance-based weights (as a standard weighted regression would do); 
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

{pstd}{cmd:lpdid} performs the Local Projections Difference-in-Differences estimator (LP-DiD) proposed by Dube, Girardi, Jordà and Taylor (2023). {p_end}

{pstd} LP-DiD is a convenient and flexible regression-based framework for implementing Difference-in-Differences. 
It uses panel data to estimate the average effect of a treatment under the assumptions of no-anticipation and (conditional) parallel trends. 
It can provide both dynamic event study estimates that track the treatment effect path at each time horizon after treatment, 
and 'pooled' estimates of the overall average effect in a post-treatment time window. 
Treatment can be absorbing (once a unit gets treated, it stays treated) or non-absorbing 
(units can enter and exit treatment multiple times). 
If treatment is non-absorbing, the nonabsorbing() option must be specified. 
The estimation sample is restricted to units entering treatment and 'clean' controls, 
thus avoiding the 'negative-weights' bias of TWFE estimators. The baseline version estimates 
a variance-weighted effect with strictly positive weights. 
The reweighed version (implemented through the rw option) estimates an equally-weighted average effect. 
LP-DiD offers flexibility in using either the last period before treatment (the default option) or an average of pre-treatment periods 
(the pmd() option) as the pre-treatment base period. 
It is possible to include pre-treatment lags of the outcome (or of other time-varying covariates) as control variables. 
See Dube, Girardi, Jordà and Taylor (2023) for a detailed exposition. {p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
This program requires the user-written commands bootstrap, reghdfe, and the packages in egenmore. {p_end}
{pstd}

{marker examples}{...}
{title:Example with absorbing treatment}

{p 4 8}Upload simulated dataset with absorbing treatment{p_end}
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

{p 4 8}Run baseline version of LP-DiD (variance-weighted with strictly positive weights), with time-window of 5 periods to define clean controls {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5)}
    {p_end}

{p 4 8}Use only non-yet treated as controls {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5, notyet)}
    {p_end}

{p 4 8}Use only non-yet treated as controls and avoid composition effects {p_end}
{p 8 12 2}
    {stata lpdid Y, time(time) unit(unit) treat(treat) pre(5) post(10) nonabs(5, notyet) nocomp}
    {p_end}

{marker results}{...}
{title:Stored Results}

{cmd:lpdid} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Macros}{p_end}

{synopt :{cmd:e(results)}} Event study estimates, with coefficients, standard errors, t-values, p-value, confidence interval (low), confidence interval (high), observation number {p_end}
{synopt :{cmd:e(pooled_results)}} Pooled estimates, with coefficients, standard errors, t-values, p-value, confidence interval (low), confidence interval (high), observation number {p_end}

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

{pstd}We are grateful to Enrique Pinzon (StataCorp), Liss Hall, Arin Dube, Òscar Jordà and Alan M. Taylor{p_end}

{pstd}If you use this package, please cite both the package and the paper introducing the LP-DiD method:{p_end}

{phang2}Busch A. and D. Girardi. 2023. 
{browse "https://ideas.repec.org/c/boc/bocode/s459273.html":"LPDID : Stata module implementing Local Projections Difference-in-Differences (LP-DiD)."}
{it:Statistical Software Components} S459273, Boston College Department of Economics.{p_end}

{phang2}and

{phang2}Dube, A., D. Girardi, Ò. Jordà and A. M. Taylor. 2023. 
{browse "https://www.nber.org/papers/w31184":"A Local Projections Approach to Difference-in-Differences."}
{it:NBER Working Paper} 31184.{p_end}


