{smcl}
{* First Version May 10 2023}{...}
{* This Version July 17 2025}{...}
{viewerdialog locproj "dialog locproj"}{...}
{vieweralsosee "[R] lincom" "help lincom"}{...}
{vieweralsosee "[R] margins" "help margins"}{...}
{vieweralsosee "[R] weights" "help weights"}{...}
{vieweralsosee "[R] ivregress post-estimation" "help ivregress postestimation"}{...}
{viewerjumpto "Syntax" "locproj##syntax"}{...}
{viewerjumpto "Stored results" "locproj##results"}{...}
{viewerjumpto "Examples" "locproj##Examples"}{...}
{viewerjumpto "Margins" "locproj##marginal_effects"}{...}
{hline}
Help for {hi:locproj}
{hline}

{title:Description}

{p}{cmd:locproj} estimates linear and nonlinear Impulse Response Functions (IRF) based on the local projections methodology first proposed by Jordà (2005). 
The procedure allows easily implementation of several options used in the growing literature of local projections. {p_end}

{p}{cmd:locproj} reports the IRF, together with its standard error and confidence interval, as an output matrix and through an IRF graph. 
The user can easily choose different options for the desired IRF graph, as well as other options to save and use the results.{p_end}

{p}{cmd:locproj} allows the user to choose different estimation methods for both time series and panel data, including some instrumental variables methods currently available in Stata such as {cmd:ivregress} or {cmd:xtivreg}, or quantile regressions methods such as  {cmd:qreg} or {cmd:ivqregress}.{p_end}

{p}{cmd:locproj} uses the Stata command {cmd:lincom} to estimate the response to the shock variable or variables, allowing to estimate responses to linear
combinations of variables, including interactions with factor or continuous variables. Importantly, it also allows the use of marginal effects instead of 
regression coefficients, which is highly convenient when the response variable is binary and the user wants to estimate the response as a probability.
In the latter case, {cmd:locproj} makes use of the Stata command {cmd:margins}, which could further facilitate the estimation of responses when 
the shock corresponds to an interaction of variables (factor or continuous) instead of just a single variable.{p_end}

{p}{cmd:locproj} also allows different options regarding the horizon and the response starting period. For instance, it allows having initial steps 
different from zero, including negative starting horizons, automatically adjusting the output and the way in which the lags of the 
dependent variable are included. {p_end}

{p}We can also use {cmd:locproj} to estimate an Event Study based on the DiD estimator in the case where the treatment period is the same for all treated individuals.{p_end}

{p}{cmd:locproj} generates temporary variables with the necessary transformations of the response variable in order to estimate the IRF 
in the desired transformation option, such as levels, logs, differences, log-differences, cumulative changes or cumulative log-differences.
 
{p}For every option, the procedure also generates temporary variables with the corresponding transformation of the dependent variable 
needed in case the user wants to include lags of the dependent variable that are consistent with the chosen transformation.{p_end}

{p}The options allow defining the desired specification in a fully automatic or in a more explicit way, with many alternatives in between. {p_end}

{p}If the user chooses the automatic specification, the syntax is very close to a typical regression command in Stata, 
with the only restriction that {cmd:locproj} interprets the variable that corresponds to the shock (impulse) as the one just after 
the dependent variable or its lagged terms, and only that one variable represents the shock. {p_end}

{p}Alternatively, the user can choose to explicitly define the shock variable (or variables), the number of lags of the shock, the number of lags 
of the dependent variable, and the control variables. As mentioned before, the user can play with alternatives between the 
fully automatic or the fully explicit, depending on which option is easier or more convenient to use.{p_end}

{p}The explicit option is recommended when the shock should include more than one variable, for instance, an additional non-linear term, 
or an interaction with another variable.
{p_end} 

{p 4 8 2}{bf:Remark:} {cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see {help weight}.{p_end}


{title:Proceedings USA Stata Conference 2023} 

https://www.stata.com/meeting/us23/slides/US23_Ugarte-Ruiz.pdf


{synoptline}
{marker index}{...}
{title:Index}

{synopt :{helpb locproj##syntax:Syntax}} Automatic and/or Explicit Syntax{p_end}

{synopt :{helpb locproj##options:Options}}{p_end}
{synopt :{helpb locproj##specification:Model Specification}} Options for defining the model specification {p_end}
{synopt :{helpb locproj##transformation:Transformation}} Options for transforming the dependent variable and its lags {p_end}
{synopt :{helpb locproj##marginal_effects:Marginal Effects}} Available options when using marginal effects {p_end}
{synopt :{helpb locproj##estimation:Estimation Method}} Estimation Method options {p_end}
{synopt :{helpb locproj##display:Displaying Results by Step}} Options for displaying step by step results (at every horizon) {p_end}
{synopt :{helpb locproj##irf_options:IRF Options}} Options for changing and saving the IRF and its confidence bands{p_end}
{synopt :{helpb locproj##graph_options:Graph Options}} Options for modifying the IRF graph{p_end}
{synopt :{helpb locproj##ivtests:Instrumental Variables Tests}} Options for testing for overindentifying restrictions and other IV tests{p_end}

{synopt :{helpb locproj##results:Stored results}}{p_end}

{synopt :{helpb locproj##Examples:Examples}}{p_end}

{synopt :{helpb locproj##example1:Example 1}} Defining the basic specification options{p_end}

{synopt :{helpb locproj##example1_1:Example 1.1}} Specification of shock and control variables {p_end}
{synopt :{helpb locproj##example1_2:Example 1.2}} Specification of lags of dependent variable, shock and control variables {p_end}
{synopt :{helpb locproj##example1_3:Example 1.3}} Specification of horizon length (steps) {p_end}
{synopt :{helpb locproj##example1_4:Example 1.4}} Estimation method options{p_end}
{synopt :{helpb locproj##example1_5:Example 1.5}} Displaying all the regression outputs from each step{p_end}
{synopt :{helpb locproj##example1_6:Example 1.6}} Use of the transformation options{p_end}
{synopt :{helpb locproj##example1_7:Example 1.7}} Changing the confidence level or using more than one level{p_end}
{synopt :{helpb locproj##example1_8:Example 1.8}} Saving the IRF results into new variables{p_end}
{synopt :{helpb locproj##example1_9:Example 1.9}} Options for plotting the IRF {p_end}

{synopt :{helpb locproj##example2:Example 2}} Interaction of a dummy variable with the shock (State-dependent IRF){p_end}
{synopt :{helpb locproj##example3:Example 3}} Non-linear effects and interactions: Using the option lcs() {p_end}
{synopt :{helpb locproj##example4:Example 4}} More complicated interactions using the option lcs() {p_end}

{synopt :{helpb locproj##example4_1:Example 4.1}} Quadratic terms {p_end}
{synopt :{helpb locproj##example4_2:Example 4.2}} Interaction with a continuous variable {p_end}

{synopt :{helpb locproj##example5:Example 5}} Example using Quantile Regression and LPGRAPH command{p_end}
{synopt :{helpb locproj##example6:Example 6}} Using instrumental variables methods {p_end}
{synopt :{helpb locproj##example7:Example 7}} Binary dependent variable: Using the option margins{p_end}
{synopt :{helpb locproj##example8:Example 8}} D-i-D Event Study{p_end}

{synoptline}


{marker syntax}{...}
{title:Syntax}

{pstd}
Automatic Specification (Shock and Lags)

{p 8 13 2}
{cmd:locproj}
{depvar}
{it:shock}
[{it:depvar lagged-terms}]
[{it:shock lagged-terms}]
[{it:controls}]
{ifin}
[{it:{help locproj##weight:weight}}]
{cmd:,}
[ {opt h:or(numlist integer)} {opt lcs(string)} {opt lco:pt(string)} {opt fc:ontrols(varlist)} {opt ins:tr(string)} {opt tr:ansf(string)} 
{opt m:et(string)} {it:model_options} {opt hopt(string)} {opt conf(numlist integer)} {opt noi:sily} {opt st:ats} {opt save:irf} {opt irfn:ame(string)} 
{opt f:act(real)} {opt marg:ins} {opt mrfv:ar(varlist)} {opt mrpr:ed(string)} {opt mro:pt(string)} {opt nograph} {opt ti:tle(string)} 
{opt lab:el(string)} {opt z:ero} {opt lcol:or(string)} {opt tti:tle(string)} {opt grn:ame(string)} {opt grs:ave(string)} 
{opt as(string)} {opt gro:pt(string)} {opt ivt:est(string)}  ]{p_end}
	

{pstd}
Explicit Specification (Shock and Lags)

{p 8 13 2}
{cmd:locproj}
{depvar}
{ifin}
[{it:{help locproj##weight:weight}}]
{cmd:,}
[ {opt h:or(numlist integer)} {opt s:hock(varlist)} {opt c:ontrols(varlist)} {opt yl:ags(integer)} {opt sl:ags(integer)} {opt lcs(string)} 
{opt lco:pt(string)} {opt fc:ontrols(varlist)} {opt ins:tr(string)} {opt tr:ansf(string)} {opt m:et(string)} {it:model_options} {opt hopt(string)} 
{opt conf(numlist integer)} {opt noi:sily} {opt st:ats} {opt save:irf} {opt irfn:ame(string)} {opt f:act(real)} {opt marg:ins} {opt mrfv:ar(varlist)} 
{opt mrpr:ed(string)} {opt mro:pt(string)} {opt nograph} {opt ti:tle(string)} {opt lab:el(string)} {opt z:ero} {opt lcol:or(string)} 
{opt tti:tle(string)} {opt grn:ame(string)} {opt grs:ave(string)} {opt as(string)} {opt gro:pt(string)} {opt ivt:est(string)} ]{p_end}

{synoptline}

{p 4 8 2}See help {help lpgraph} for using the post-estimation command {cmd:lpgraph} that allows plotting together results of different estimations.{p_end}

{synoptline}

{synoptset 33 tabbed}{...}
{marker Options}{...}
{synopthdr:Options}
{synoptline}

{marker specification}{...}
{syntab:{bf:Model Specification:}}

{synopt:{opt h:or(numlist/integer)}}Specifies the number of steps or horizon length for the IRF. The initial horizon could be negative.
It can be specified either as a range (e.g. {it:hor(0/6)} or {it:hor(-3/6)}), or just as the final horizon period (e.g. {it:hor(6)}) 
in which case the command assumes the horizon starts at period 0 and ends in period 6. The default horizon range is {it:hor = 0,...,5} 
if nothing is specified.{p_end}

{synopt:{opt s:hock(varlist)}}Allows to explicitly define the variable or variables that represent the shock or impulse that 
will generate the response and the IRF. If this option is not specified the command will automatically choose the first variable that 
is immediately after the {depvar} and its lagged terms if they are included in the main {it:varlist}.
This option should be used when the desired shock includes more than one variable, for instance a non-linear term or 
an interaction term.{p_end}

{synopt:{opt lcs(string)}}Specifies an expression, usually an addition of variables, that defines a linear combination of variables that represents 
the desired impulse (shock).  This option should be used when the desired shock includes more than one variable and the name of one of them 
is not explicitly included in the syntax variable list, for instance the constant term ({it:_cons}), or the expansion of an expression that
includes factor variable terms, e.g. {it:12.code#c.xvar}. The expression that should go inside the parenthesis is analogous to any expression 
that is tested using the commands {cmd:lincom} or {cmd:test}.{p_end}

{synopt:{opt sl:ags(integer)}}Specifies explicitly the number of lags of the shock variable or variables that should be included in the specification.
The lagged terms of the shock could also be included directly in the main {it:varlist} next to the first variable that represents the shock.
If more than one variable is specified through the option {opt s:hock()} then the specification will include lags of all of them.{p_end}

{synopt:{opt yl:ags(integer)}}Specifies explicitly the number of lags of the {depvar} that should be included in the specification. 
The way the lags of the dependent variable are included changes depending on the type of tranformation that is defined by the user 
through the option {opt tr:ansf()}.{p_end}

{synopt:{opt c:ontrols(varlist)}}Allows to explicitly define the variable or variables that represent the control variables. 
If this option is not specified the command simply includes all the variables that are immediately after the shock variable(s) 
and its lagged terms if they are included in the main {it:varlist}. 
The control variables could include any number of lags, interactions, or any other desired transformations.{p_end}

{synopt:{opt fc:ontrols(varlist)}}Specifies any control variable(s) that should be included at the same horizon as the IRF, 
i.e. that their forecast should be included depending on the horizon, i.e. {it:fcontrol(t+h)} with {it:h = 0...hor}.{p_end}

{synopt:{opt lco:pt(string)}}Specifies any option available in the command {cmd:lincom}. See {help lincom} for specific help about 
the command {cmd:lincom}{p_end}


{marker transformation}{...}
{syntab:{bf:Transformation Options:}}

{synopt:{opt tr:ansf(string)}}Specifies the type of transformation that should be applied to the dependent variable when generating the forecasts that are used for each 
horizon of the local projection. The available transformations available are the ones in the following list, and they should be written exactly as they are shown:{p_end}

{p 39 42 2}1. {bf:(level)}: {it:Levels: }It keeps the dependent variable as originally specified and uses its forecast {it:h} periods ahead 
for each horizon of the IRF, i.e. {it:y(t+h)} with {it:h = 0...hor}. It is the default option in case no transformation is specified. 
When the option {opt yl:ags()} is specified, it includes lags of the variable in levels, i.e. {it:y(t-l)} with {it:l = 1,...,ylags}.{p_end}

{p 39 42 2}2. {bf:(diff)}: {it:Differences: }It uses forecasts of the dependent variable in simple "differences", i.e. {it:y(t+h) - y(t+h-1)} 
with {it:h = 0...hor}. When the option {opt yl:ags()} is specified, it includes lags of the variable in differences, i.e. {it:y(t)-y(t-l)} 
with {it:l = 1,...,ylags}.{p_end}

{p 39 42 2}3. {bf:(cmlt)}: {it:Cumulative differences: }It uses forecasts of the dependent varible in cumulative differences, 
i.e. {it:y(t+h) - y(t-1)} with {it:h = 0...hor}. When the option {opt yl:ags()} is specified, it includes lags of the variable 
in differences, i.e. {it:y(t)-y(t-l)} with {it:l = 1,...,ylags}.{p_end}

{p 39 42 2}4. {bf:(logs)}: {it:Logs: }It uses forecasts of the logarithm of the dependent varible, i.e. {it:ln(y(t+h))} with {it:h = 0...hor}. 
When the option {opt yl:ags()} is specified, it includes lags of the logarithm of the variable, i.e. {it:ln(y(t-l))} with {it:l = 1,...,ylags}.{p_end}

{p 39 42 2}5. {bf:(logs diff)}: {it:Log-differences: }It uses forecasts of the dependent variable in differences of its natural logarithm, 
i.e. {it:ln(y(t+h)) - ln(y(t+h-1))} with {it:h = 0...hor}. When the option {opt yl:ags()} is specified, it includes lags of the variable in log-differences, 
i.e. {it:ln(y(t))-ln(y(t-l))} with {it:l = 1,...,ylags}.{p_end}

{p 39 42 2}6. {bf:(logs cmlt)}: {it:Cumulative log-differences: }It uses forecasts of the dependent variable in cumulative differences of its natural logarithm, 
i.e. {it:ln(y(t+h)) - ln(y(t-1))} with {it:h = 0...hor}. When the option {opt yl:ags()} is specified, it includes lags of the variable in log-differences, 
i.e. {it:ln(y(t))-ln(y(t-l))} with {it:l = 1,...,ylags}.{p_end}


{marker marginal_effects}{...}
{syntab:{bf:Marginal Effects Options:}}

{synopt:{opt marg:ins}}Specifies that the marginal effect of the shock variable is used instead of the regression coefficients. 
For simplicity, it only allows using the dydx option of the command {cmd:margins}. See {help margins} for specific help about 
the command {cmd:margins}{p_end}

{synopt:{opt mrfv:ar(varlist)}}Specifies the factor or continuous variable that it is interacted with the shock variable in the specification.
This option should be used together with the {opt s:hock(varlist)} option and the {opt marg:ins} option.{p_end} 

{synopt:{opt mrpr:ed(string)}}Specifies the option to be used with the predict command to produce the variable that will be used as the response 
when using the {opt marg:ins} option, e.g. {it:pr}, {it:pc1}, {it:pu0}, {it:xb}. It this option is not specified it uses the default option of the estimation method being used.{p_end}

{synopt:{opt mro:pt(string)}}Allows to specify other options available in the command {cmd: margins} that have not been specified in the previous marginal effect options. 
 See {help margins} for specific help about using the command {cmd:margins}.{p_end}


{marker estimation}{...}
{syntab:{bf:Estimation Method:}}

{synopt:{opt m:et(string)}}Specifies the estimation method. The default is {cmd:xtreg} when using panel data and {cmd:reg} 
when using time-series data. Any estimation method with a standard syntax is allowed. Additionally, the command allows 
to use the instrumental variable commands {cmd:ivregress} and {cmd:xtivreg} and other IV methods with a similar syntax.
In the specific case of {cmd:ivregress}, the user also has to specify the "estimator" within the {opt met()} option 
in the following way: 
{bf:met(ivregress {it:estimator})}, where {it:estimator} could be either on of {it: 2sls, liml or gmm}. 
When any IV method is specified, a list of instruments must also be provided through the option {opt instr(varlist)}.{p_end}

{synopt:{opt ins:tr(varlist)}}Specifies the variables to use as instruments for the impulse (shock) variable when using an 
instrumental variable method such as {cmd:ivregress} or {cmd:xtivreg}. The shock variable must be defined as 
in any of the model specification available options.{p_end}

{synopt:{opt hopt(string)}}Specifies any methodological option that depends directly on the horizon of the IRF, i.e. any option 
that must change with every step/horizon of the IRF {it:h = 0...hor}.{p_end}

{synopt:{it:model_options}}Specifies any other estimation options specific to the method used and not defined elsewhere. 
If the user wants to specify any methodological option corresponding to the estimation method being used, she only has to 
enter them alongside the rest of {cmd:locproj} options.{p_end}


{marker display}{...}
{syntab:{bf:Displaying Results:}}

{synopt:{opt noi:sily}}If this option is specified, the command displays a regression output for each one of the horizons. If this option 
is not specified the command only returns a matrix with the IRF, its standard error and the confidence bands. {p_end}

{synopt:{opt st:ats}}If this option is specified, the command displays a table with the summary statistics of the estimated regression
at each step/horizon. The table includes the number of observations, the R-squared or pseudo-R-squared, the F-statistic or Chi2-statistic,
and the p-value (prob) of the respective statistic. {p_end}


{marker irf_options}{...}
{syntab:{bf:IRF Options:}}

{synopt:{opt conf(numlist)}}Specifies one or (max) two confidence levels for calculating the confidence bands. The default is 95%. {p_end}

{synopt:{opt save:irf}}If this option is specified, the IRF, its standard error and the confidence bands are saved as new variables, otherwise 
no new variables are created. If this option is specified, the command assigns a default name to the new generated variables.{p_end}

{synopt:{opt irfn:ame(string)}}Specifies a name/prefix for the new IRF variable and the other new generated variables (standard error 
and confidence bands).{p_end}

{synopt:{opt f:act(real)}}Specifies a factor for scaling the IRF, for instance, if the user wants to express the log difference transformation 
in percentage terms, this option should be specified as fact(100).{p_end}


{marker graph_options}{...}
{syntab:{bf:Graph Options:}}

{synopt:{opt nograph}}If this option is specified a graph is not displayed.{p_end}

{synopt:{opt z:ero}}If this option is specified the graph includes a dashed line for the value 0.{p_end}

{synopt:{opt ti:tle(string)}}Specifies a title for the IRF graph.{p_end}

{synopt:{opt lcol:or(string)}}Specifies a color for the IRF line and the confidence bands.{p_end}

{synopt:{opt lab:el(string)}}Specifies a label for the IRF line in the IRF graph.{p_end}

{synopt:{opt tti:tle(string)}}Specifies a name for the time axis in the IRF graph.{p_end}

{synopt:{opt grn:ame(string)}}Specifies a graph name that could be used, for instance, when combining various graphs.{p_end}

{synopt:{opt grs:ave(string)}}Specifies a file name and path that should be used to save the IRF graph on the disk.{p_end}

{synopt:{opt as(string)}}Specifies the desired file format of the saved graph.{p_end}

{synopt:{opt gro:pt(string)}}Specifies any other graph options not defined elsewhere.{p_end}


{marker ivtests}{...}
{syntab:{bf:Instrumental Variables Tests:}}

{synopt:{opt ivt:est(string)}}If this option is specified, the command performs and displays one out of the three postestimation tests 
that are available after using the command {cmd:ivregress}, for each step/horizon. The three available tests are the endogeneity 
test (endogenous), first-stage regression statistics (firststage), and the test of overindentifying restrictions (overid).
The user has to write inside the parenthesis the exact name of the test, either {it: endogenous}, {it: firststage} or {it: overid}, and if necessary/desired, 
a comma and the corresponding/available test options. See {help ivregress} and {help ivregress postestimation} for specific help about using the post-estimation 
commands available after using the command {cmd:ivregress}.{p_end}


{synoptline}
{marker weight}{...}
{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are
allowed; see {help weight}.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:locproj} stores the following in {cmd:e()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{bf:e(irf)}}A matrix including the Impulse Response Function (IRF), its standard error and its confidence interval.{p_end}
{synopt:{bf:e(stats)}}A matrix including the regression statistics by each step/horizon.{p_end}

{p2col 5 18 22 2: Name of Generated Variables if no name is defined:}{p_end}

{synopt:{bf:_birf}} estimated impulse response function (IRF).{p_end}
{synopt:{bf:_seirf}} IRF's standar error {p_end}
{synopt:{bf:_irfup}}  IRF's upper confidence interval {p_end}
{synopt:{bf:_irflo}}  IRF's lower confidence interval {p_end}
{synopt:{bf:_irfup2}}  second IRF's upper confidence interval {p_end}
{synopt:{bf:_irflo2}}  second IRF's lower confidence interval {p_end}


{p2col 5 18 22 2: Name of Generated Variables if the name given to the IRF is "irfname":}{p_end}

{synopt:{bf:irfname}} estimated impulse response function (IRF).{p_end}
{synopt:{bf:irfname_se}} IRF's standar error {p_end}
{synopt:{bf:irfname_lo}}  IRF's lower confidence interval {p_end}
{synopt:{bf:irfname_up}}  IRF's upper confidence interval {p_end}
{synopt:{bf:irfname_up2}}  second IRF's upper confidence interval {p_end}
{synopt:{bf:irfname_lo2}}  second IRF's lower confidence interval {p_end}

{synoptline}

{marker Examples}{...}
{title:Examples}

{title:Example 1. Defining the basic options }

{p 4 4 0}Throughout examples 1.1 to 1.9 we are interested in estimating the IRF from a shock to the variable {bf:n} (Growth rate of hours worked) 
into the variable {bf:y} (Growth rate of real GDP){p_end} 

{p 4 8 0}. {stata webuse set www.stata-press.com/data/r17/}

{p 4 8 0}. {stata webuse usmacro2.dta, clear}{p_end}

Or

{p 4 8 2}. {stata use usmacro2.dta, clear}{p_end}

{marker example1}{...}
{marker example1_1}{...}

{title:Example 1.1 Specification of shock and control variables}

{p 4 4 0}What the automatic vs. explicit specification means is that the user can let {cmd:locproj} interpret in an automatic way
which variables provided on the {it:varlist} correspond to the dependent variable, which one is the shock, 
which ones are control variables, and also which ones are just lags of each type of variable. Alternatively,
in more complicated cases, the user can specify all those details in a explicit way using the available options for 
such cases.{p_end}

{p 4 4 0}The simplest local projection specification in which the response variable is {bf:y} and the shock variable is {bf:n} would be 
(automatic specification):{p_end}

{p 8 8 2}. {stata locproj y n}{p_end}

{p 4 4 0}Which would also be equivalent to the following (explicit specification):

{p 8 8 2}. {stata locproj y, shock(n)}{p_end}

{p 4 4 0}We can also add control variables by adding them after the shock one or using the option controls. In this case our control
variable is {bf:r}

{p 8 8 2}. {stata locproj y n r}{p_end}

{p 4 4 0}Which would be equivalent to the following (explicit specification):

{p 8 8 2}. {stata locproj y, shock(n) controls(r)}{p_end}

{synopt :{helpb locproj##index:Return to Index}}{p_end}

{marker example1_2}{...}
{title:Example 1.2 Specification of lags of dependent variable, shock and control variables}

{p 4 4 0}We might want to include lags of the dependent variable, the shock or the control variables.
For the dependent variable and the shock, there are explicit options, whether for the control variables you just need
to add them either on the {it:varlist} or as additional variables in the {bf:controls()} option.
 
{p 4 4 0}In all of the following examples we define that the dependent variable has one lag, that the shock
variable has 2 lags and that the control variable has 3 lags. They all are exactly equivalent:{p_end}

{p 4 4 0}{it: Automatic specification}

{p 4 8 2}. {stata locproj y l.y l2.y n l.n l2.n r l.r l2.r l3.r}{p_end}
{p 4 8 2}. {stata locproj y l.y l2.y l(0/2).n l(0/3).r}{p_end}
{p 4 8 2}. {stata locproj l(0/2).y l(0/2).n l(0/3).r}{p_end}

{p 4 4 0}{it: Explicit or intermmediate specification}

{p 4 8 2}. {stata locproj y n, controls(l.y l2.y l.n l2.n r l.r l2.r l3.r)}{p_end}
{p 4 8 2}. {stata locproj y, shock(n) controls(l.y l2.y l.n l2.n r l.r l2.r l3.r)}{p_end}
{p 4 8 2}. {stata locproj y, s(n) controls(l(1/2).y l(1/2).n l(0/3).r)}{p_end}

{p 4 4 0}{it: Using the ylags and slags options}

{p 4 8 2}. {stata locproj y n, ylags(2) slags(2) controls(l(0/3).r)}{p_end}
{p 4 8 2}. {stata locproj y, s(n) ylags(2) slags(2) controls(l(0/3).r)}{p_end}

{synopt :{helpb locproj##index:Return to Index}}{p_end}

{marker example1_3}{...}
{title:Example 1.3. Specification of horizon length (steps)}

{p 4 4 0}We can define the horizon either as an interval or just by specifying the final step/horizon:{p_end}

{p 4 8 2}. {stata locproj y n, hor(0/12) yl(2) sl(2) c(l(0/2).r)}{p_end}
{p 4 8 2}. {stata locproj y n, hor(12) yl(2) sl(2) c(l(0/2).r)}{p_end}

{p 4 4 0}The initial step can be different from zero, either negative or positive, but it always has to be an integer number.
In cases in which the horizon is different from zero, {cmd:locproj} adjusts the output accordingly, and in the cases
of negative horizons, it also adjusts the way in which the lags of the dependent variable are included. {p_end}

{p 4 8 2}. {stata locproj y n, h(-3/12) yl(2) sl(2) c(l(0/2).r)}{p_end}
{p 4 8 2}. {stata locproj y n, h(1/12) yl(2) sl(2) c(l(0/2).r)}{p_end}

{synopt :{helpb locproj##index:Return to Index}}{p_end}

{marker example1_4}{...}
{title:Example 1.4. Estimation method options}

{p 4 4 0}We want to use the Newey-West as the estimation method in order to correct for autocorrelation, which consequently requires specifying 
that the option "lag" in the Newey-West command should depend on the horizon of the IRF in the following way: {p_end}

{p 4 8 2}. {stata locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag)}{p_end}

{p 4 4 0}We can add any other existing methodological option corresponding to the method introduced in the option {opt met()} simply by 
writing it down after the comma, as long as that option has a different name to any of the existing {cmd:locproj} options. For instance, 
we can include the option of no-constant term by adding the option {opt noconstant}: {p_end}

{p 4 8 2}. {stata locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag) noconstant}{p_end}


{synopt :{helpb locproj##index:Return to Index}}{p_end}

{marker example1_5}{...}
{title:Example 1.5. Displaying all the regression outputs}

{p 4 4 0}If we want to take a look at the regression output for each one of the horizons of the IRF we can use the options {opt noisily} 
and {opt stats}. The regression outputs displayed when using the otpion {opt noisily} are not the exact outputs from whatever estimation method 
we are using, but a simplified output table. The reason for this is that {cmd: locproj} uses temporary variables whose given names do not 
have any meaning and would be difficult to understand. {cmd: locproj} generates a new output table with variable names related to the variable 
list defined by the user.{p_end} 

{p 4 8 2}. {stata locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag) noisily}{p_end}

{p 4 4 0}The {bf:stats} option generates a table with each regression statistics for every horizon, i.e. number of observations, R-squared 
or pseudo-R-squared, F-statistic or Chi2-statistic and their respective p-values.{p_end}

{p 4 8 2}. {stata locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag) stats}{p_end}

{synopt :{helpb locproj##index:Return to Index}}{p_end}

{marker example1_6}{...}
{title:Example 1.6. Use of the transformation options}

{p 4 4 0}In this example we are going to estimate the IRF from a shock to the variable {bf:r} (FED funds rate) into the variable {bf:i} 
(corporate bond interest rate (AAA)) using the different transformation options. In order to express the result in percentage terms, 
we also make use of the option {bf:fact()} and we scale the response by a factor of 100.{p_end}

{p 4 4 0}We first need to generate the variables in logarithm and their differences in order to compare the results:{p_end}

{p 4 8 2}. {stata gen lni = ln(i)}{p_end}
{p 4 8 2}. {stata gen lnr = ln(r)}{p_end}
{p 4 8 2}. {stata gen dlni = d.lni}{p_end}
{p 4 8 2}. {stata gen dlnr = d.lnr}{p_end}

{p 4 4 0}We first estimate the IRF using the two variables in logarithm:{p_end}

{p 4 8 2}. {stata locproj lni lnr, f(100) yl(2) sl(2)}{p_end}

{p 4 4 0}But we can also estimate the same by using the option {bf:transf(logs)} for the dependent variable:{p_end}

{p 4 8 2}. {stata locproj i lnr, f(100) yl(2) sl(2) tr(logs)}{p_end}

{p 4 4 0}We can estimate the model in differences by entering the log-difference as the dependent variable:{p_end}

{p 4 8 2}. {stata locproj d.lni lnr, f(100) yl(2) sl(2)}{p_end}

{p 4 4 0}However, we can also use the option {bf:transf(diff)} with the dependent variable in logs:{p_end}

{p 4 8 2}. {stata locproj lni lnr, f(100) yl(2) sl(2) tr(diff)}{p_end}

{p 4 4 0}Or we can also use the option {bf:transf(logs diff)} with the dependent variable in levels:{p_end}

{p 4 8 2}. {stata locproj i lnr, f(100) yl(2) sl(2) tr(logs diff)}{p_end}

{p 4 4 0}For estimating the model in cumulative differences we can do it with both variables in logarithm:{p_end}

{p 4 8 2}. {stata locproj lni lnr, f(100) yl(2) sl(2) tr(cmlt)}{p_end}

{p 4 4 0}Which would be equivalent to estimate the model with the variable {bf:i} in levels and using the option {bf:tr(logs cmlt)}:{p_end}

{p 4 8 2}. {stata locproj i lnr, f(100) yl(2) sl(2) tr(logs cmlt)}{p_end}


{synopt :{helpb locproj##index:Return to Index}}{p_end}

{marker example1_7}{...}
{title:Example 1.7. Changing the confidence level or using more than one level}

{p 4 4 0}By default the confidence level for the confidence bands is 95%. If we want to change it, we can use the {opt conf()} option
which admits a maximum of two levels and only admits integer values:{p_end}

{p 4 8 2}. {stata locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag) conf(90)}{p_end}

{p 4 8 2}. {stata locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag) conf(66 99)}{p_end}

{synopt :{helpb locproj##index:Return to Index}}{p_end}

{marker example1_8}{...}
{title:Example 1.8. Saving the IRF results into new variables}

{p 4 4 0}If we want to save the estimated IRF into a new variable that can be used later, we can use it through the options {bf:saveirf} and {bf:irfname()}.
If we just type {bf:saveirf}, {cmd: locproj} generates four (or six) new variables with the IRF, its standard error and the confidence bands.
{cmd:locproj} uses some predetermined default names to save the corresponding variables (_irf, _seirf, _irf_lo and _irf_up), but if we want 
to give them a name of our preference (e.g. {it:newirf}), we can do it through the option {bf:irfname()}:{p_end}

{p 4 8 2}. {stata locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag) saveirf}{p_end}

{p 4 8 2}. {stata locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag) save irfname(newirf)}{p_end}

{synopt :{helpb locproj##index:Return to Index}}{p_end}

{marker example1_9}{...}
{title:Example 1.9. Some graph options}

{p 4 4 0}If we do not want {cmd:locproj} to produce a graph, we just have to type {bf:nograph}:{p_end}

{p 4 8 2}. {stata locproj y l(0/4).n l(0/4).r, h(12) m(newey) hopt(lag) yl(3) nograph}{p_end}

{p 4 4 0}In the following example we are going to produce a graph in which a dashed-line with the value of zero is included, we are goint to give  the graph the tittle "LP Example", include a label "Hours worked", change the color of the IRF line and its confidence interval 
to red instead of blue, and define the time axis as "Number of Days":{p_end}

{p 4 8 2}. {stata locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag) zero title("LP Example") label("Hours worked") lcolor(red) ttitle("Number of quarters") conf(66 95)}{p_end}

{p 4 4 0}Next, we are going to give the graph a name, we are going to save it in a folder in our disk as a png file named "example1":{p_end}

{p 4 8 2}. {cmd: locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag) zero title(LP Example) grname(Example1) grsave("C:\Documents\example1.png") as(png)}{p_end}

{p 4 4 0}We can also add other graph options inside the {opt gropt()} option, for instance, we can define the labels of the y-axis and change the 
background color to white:{p_end}

{p 4 8 2}. {stata locproj y l.y l(0/2).n l(0/3).r, h(12) met(newey) hopt(lag) zero title(LP Example) gropt(graphregion(fcolor(white)) ylabel(-0.25(0.25)1))}{p_end}


{p}{bf:Remark:} We can also combine the results of different IRFs into a single graph using the post-estimation command {cmd:lpgraph}. See {help lpgraph} for specific help about using the command {cmd:lpgraph}.{p_end}


{synopt :{helpb locproj##index:Return to Index}}{p_end}


{marker example2}{...}
{title:Example 2. Interaction of a dummy variable with the shock}

{p}We want to specify a different reaction to our shock variable before and after the global financial crisis (GFC).  
We first need to generate two dummy variables. The first dummy variable {bf:bef_gfc} is equal to one before the first quarter of 2009
and zero afterwards, meanwhile the second dummy variable {bf:aft_gfc} is equal to one after the first quarter of 2009 and zero before that.{p_end}

{p 4 8 2}. {stata gen bef_gfc = dateq<tq(2009q1)}{p_end}
{p 4 8 2}. {stata gen aft_gfc = dateq>=tq(2009q1)}{p_end}

{p}We can also generate two interaction variables, i.e. the product of the dummy variables times the shock variable {bf:n}. 
The first interaction variable is equal to {bf:n} before the GFC and equal to zero afterwards. The second interaction variable is 
equal to zero before the GFC and equal to {bf:n} afterwards.{p_end}

{p 4 8 2}. {stata gen n_bef = n*bef_gfc}{p_end}
{p 4 8 2}. {stata gen n_aft = n*aft_gfc}{p_end}

{p}The estimated IRF after the GFC corresponds to the addition of the individual coefficients of the variables {bf:n} and {bf:n_aft}. 
Thus we have to specify that the shock corresponds to both variables, which is done by including both of them inside the option {opt shock()}.
locproj will take all the variables that are included in the option {opt shock()} and add their individual effects:{p_end}

{p 4 8 2}. {stata locproj y, s(n n_aft) ylags(1) slags(2) controls(l(0/3).r) hor(12)}{p_end}

{p}We can also directly include the interaction between the dummy variable {bf:aft_gfc} and the variable n inside the option shock(), 
but crucially, we have to specify in the interaction that both variables are continuous even though the first one is a dummy, i.e. {bf:c.aft_gfc#c.n}, and we would get the same results:{p_end}

{p 4 8 2}. {stata locproj y, s(n c.aft_gfc#c.n) ylags(1) slags(2) controls(l(0/3).r) hor(12)}{p_end}

{p}The interpretation of each individual coeefficient is the following: the coefficient of the variable {bf:n} corresponds to the 
impact before the GFC, and the coefficient of the variable {bf:n_aft} corresponds to the difference between the two periods.{p_end}

{p}Alternatively, we can use the interaction variable {bf:n_bef} to estimate the IRF resulting from the shock variable {bf:n} before 
the GFC in the following way:{p_end}

{p 4 8 2}. {stata locproj y, s(n_bef n) ylags(1) slags(2) controls(l(0/3).r) hor(12)}{p_end}

{p}Which is equivalent to (using an interaction of two continuous variables):{p_end}

{p 4 8 2}. {stata locproj y, s(c.bef_gfc#c.n n) ylags(1) slags(2) controls(l(0/3).r) hor(12)}{p_end}

{p}In this case, the IRF before the GFC corresponds to the addition of the individual coefficients of the variables {bf:n} and {bf:n_bef}, 
meanwhile the coefficient of the variable {bf:n} corresponds to the impact after the GFC, and the coefficient of the variable {bf:n_bef}
corresponds to the difference between the two periods.{p_end}


{synopt :{helpb locproj##index:Return to Index}}{p_end}
{synoptline}

{marker example3}{...}
{title:Example 3. Non-linear effects and interactions: Using the option {opt lcs()}}

{p}We will replicate Example 2 but using the option {opt lcs()}. The use of this option is equivalent to the use of the command 
{cmd:lincom} after estimating any regression command. The expression that goes inside the parenthesis is analogous to any expression
that is tested using the commands {cmd:lincom} or {cmd:test}.

{p}We are going to use the dummy variable {bf:aft_gfc} that is equal to one after the first quarter of 2009. But now we are going to use 
the factor variables syntax to specify the shock, and thus, we will need to use the option {opt lcs()}, since the syntax of factor variables could be more complicated, although sometimes more convenient to use.{p_end}

{p}The option {opt lcs()} allows us to specify the shock in any way we want, as long as is expressed as a linear combination of the variables 
included in the model specification.{p_end}

{p}In this case, the model specification includes both the variable {bf:n} and the interaction of the GFC dummy {bf:aft_gfc} 
and the variable {bf:n}. The interpretation of the coefficients of each variable are the same as in Example 2, the coefficient 
of the variable {bf:n} corresponds to the response during the period preceding the GFC, meanhwile the coefficient 
of the variable {bf:1.aft_gfc#c.n} corresponds to the difference in the response between the two periods. Thus the total 
response after the GFC is equal to the sum of the two coefficients. 
(In this specification the variable {bf:0.aft_gfc#c.n} is omitted).{p_end}

{p 4 8 2}. {stata locproj y l(0/2)(n aft_gfc#c.n) l(0/3).r, ylags(1) lcs(n+1.aft_gfc#c.n)}{p_end}

{p}However, if we only include the interaction between the dummy and the continuous variable {bf:aft_gfc#c.n} then the response after the GFC is equal to the coefficient of the variable {bf:1.aft_gfc#c.n}, meanwhile the response before the GFC is equal to the coefficient of 
the variable {bf:0.aft_gfc#c.n}{p_end}

IRF before the GFC:

{p 4 8 2}. {stata locproj y l(0/2)(aft_gfc#c.n) l(0/3).r, ylags(1) lcs(0.aft_gfc#c.n)}{p_end}

IRF after the GFC:

{p 4 8 2}. {stata locproj y l(0/2)(aft_gfc#c.n) l(0/3).r, ylags(1) lcs(1.aft_gfc#c.n)}{p_end}
 


{synopt :{helpb locproj##index:Return to Index}}{p_end}
{synoptline}

{marker example4}{...}
{title:Example 4 More complicated interactions using the option {opt lcs()}}

{marker example4_1}{...}
{title:Example 4.1 Quadratic terms}

{p 4 4 0}If we want to estimate the response to a nonlinear shock we need to take into account that the estimated response 
might depend on the size of the shock, on the level of the interaction variable, and in some cases on the shock variable 
initial level. Therefore, the estimation depends on the coefficients and levels of more than one variable.{p_end}

{p 4 4 0}We are going to show how to estimate the case of the response when the shock includes a quadratic term, for instance, 
a quadratic term of the variable {bf:n}. In Stata we can generate a new variable equal to the square of {bf:n}:{p_end}

{p 4 8 2}. {stata gen n_2 = n^2}{p_end}

{p 4 4 0}Alternatively we can use an interaction term such as {bf:c.n#c.n}. For simplicity of the syntax, in this example we use 
the new generated variable {bf:n_2}, but the result will be exactly the same if we use {bf:c.n#c.n} instead.{p_end}

{p 4 4 0}Since the shock is composed of two variables we are going to include both {bf:n} and {bf:n_2} into the option {opt shock()} 
and we are going to write down the expression for the impulse response in this case inside the option {opt lcs()}. 
The IRF depends on the size of the shock to the variable {bf:n} and on its intial level, which we will assume equal to 
its sample average.{p_end}

{p 4 4 0}We first assume that the size of the shock is equal to one, i.e. n = 1, and therefore n_2 = 1. We then need to calculate 
and save the sample average of the variable {bf:n}.{p_end}

{p 4 8 2}. {stata sum n}{p_end}
{p 4 8 2}. {stata sca nm=r(mean)}{p_end}

{p 4 8 2}. {stata locproj y, shock(n n_2) ylags(1) slags(2) controls(l(0/3).r) hor(12) lcs(n*1+2*n_2*1*nm+n_2*1)}{p_end}

{p 4 4 0}If we want to estimate the IRF for other values of the variable {bf:n}, for instance, {bf:n = 3} and {bf:n = 5}, 
and therefore, {bf:n^2 = 9} and {bf:n^2 = 25} we would need to change the expression that goes into the option {opt lcs()}:{p_end}

{p 4 8 2}. {stata locproj y, shock(n n_2) ylags(1) slags(2) controls(l(0/3).r) hor(12) lcs(n*3+2*n_2*3*nm+n_2*9)}{p_end}

{p 4 8 2}. {stata locproj y, shock(n n_2) ylags(1) slags(2) controls(l(0/3).r) hor(12) lcs(n*5+2*n_2*5*nm+n_2*25)}{p_end}

{p 4 4 0}We can also use the option {opt margins}, although it has some limitations. We cannot use the option {opt shock()} with 
the two variables since {opt margins} can obtain the derivative of only one variable and we are indicating two different ones.{p_end} 
{p 4 4 0}Since we want to include lags of the shock variable, we cannot use the options {opt slags()}, but we need to specify the lags manually, making sure that specification includes the same lags of both n and its quadratic term as before. 
We are also going to use the interaction c.n#c.n instead of the variable n_2. {p_end}

{p 4 4 0}We also need to use the option {opt mropt()} to specify that the shock variable is evaluated at the desired initial level (its sample average), by introducing the option {opt atmeans}:{p_end}

{p 4 8 2}. {stata locproj y l(0/2)(n c.n#c.n), ylags(1) controls(l(0/3).r) h(12) margins mropt(atmeans)}{p_end}


{marker example4_2}{...}
{title:Example 4.2 .Interaction with a continuous variable}

{p 4 4 0}In this example we will estimate an IRF when the shock is a continuous variable and it interacts with another 
continuous variable. The variable that interacts is {bf:e}, the percent change in US exchange rate. As in other examples, 
we are only interested in this interaction as a way to show how to do it with {cmd:locproj} and not because 
its economic meaning or relevance.{p_end}

{p 4 4 0}This case is pretty similar to the one of a quadratic term, however in this case the initial level of the shock 
variable does not intervene. However, the idea of the interaction is to evaluate the response at different levels of 
the interaction variable. Initially, we assume that the size of the shock, {bf:n = 1}, and we want to estimate the 
response at a level of the variable {bf:e = 1}. To do so we just need to include our shock variable {bf:n} and the 
interaction term {bf:c.n#c.e} in the option {opt shock()}:{p_end}

{p 4 8 2}. {stata locproj y, s(n c.n#c.e) ylags(1) sl(3) controls(l(0/3).r) hor(12)}{p_end}

{p 4 4 0}However, if we want to estimate the response at other levels of the variable {bf:e}, for instance, at its sample mean, 
we can use the option {opt lcs()}:{p_end}

{p 4 8 2}. {stata sum e}{p_end}
{p 4 8 2}. {stata scalar em=r(mean)}{p_end}

{p 4 8 2}. {stata locproj y, s(n c.n#c.e) ylags(1) sl(3) controls(l(0/3).r) hor(12) lcs( n + c.n#c.e*em)}{p_end}

{p 4 4 0}We would obtain exactly the same result if we use the option margins in the following
way (3.1645 is the mean of e): {p_end}

{p 4 8 2}. {stata locproj y  l(0/3)(n c.n#c.e), ylags(1) controls(l(0/3).r) hor(12) margins mropt(atmeans at(e=3.164551))}{p_end}

{p 4 4 0}We can evaluate the IRF at different levels of the variable e. Evaluating the IRF at e = 6 
using the {opt option lcs()} would be given by:{p_end}

{p 4 8 2}. {stata locproj y l(0/3)(n c.n#c.e), ylags(1) controls(l(0/3).r) hor(12) lcs(n + c.n#c.e*6)}{p_end}

{p 4 4 0}We would obtain exactly the same results using the option margins in the following way:{p_end}

{p 4 8 2}. {stata locproj y l(0/3)(n c.n#c.e), ylags(1) controls(l(0/3).r) hor(12) margins mropt(atmeans at(e=6))}{p_end}


{synopt :{helpb locproj##index:Return to Index}}{p_end}
{synoptline}


{marker example5}{...}
{title:Example 5. Example using Quantile Regression and LPGRAPH command}

{p}In this example we are going to estimate the IRF of the GDP growth rate to a shock in the monetary policy interest rate {bf:r}. 
We want to estimate the IFR for different quantiles of the distribution of our dependent variable, using the quantile 
regression method {cmd:qreg}.{p_end}

{p}We want our shock variable to have an impact with a one period lag. However, the {cmd:qreg} command does not allow the use of 
time-series operators. Thus we first need to generate the variable r(t−1) and using it as our shock variable:{p_end}

{p 4 8 2}. {stata gen lr=l.r}{p_end}

{p}Nevertheless, {cmd:locproj} has been adapted so that we can include lags of the dependent variable and the shock variable 
automatically even if the estimating method we are using does not allow time-series operators. We can do it by using 
the options {opt ylags()} and {opt slags()} respectively.{p_end} 

{p}For instance, in this example we want to include three lags of y and of r(t−1). Normally, if we are using {cmd:qreg} 
we would need to generate all these lagged variables, but with {cmd:locproj} we can just write {bf:yl(3)} 
and {bf:sl(3)}.{p_end}

{p}However, if we want to include {bf:lags of our control variables}, we do need to do it by hand, generating each one of the 
lagged-terms we want. In our example, we are going to introduce three lags of the variable {bf:n}:{p_end}

{p 4 8 2}. {stata gen ln=l.n}{p_end}
{p 4 8 2}. {stata gen l2n=l2.n}{p_end}
{p 4 8 2}. {stata gen l3n=l3.n}{p_end}

{p}We are going to estimate the IRF for three moments of the variable y distribution: its mean, the 20th percentile, 
the median, and the 80th percentile. In all cases we use a robust estimator of the variance-covariance matrix. 
For the average outcome, we use OLS:{p_end}

{p 4 8 2}. {stata locproj y lr n ln l2n l3n, yl(3) sl(3) h(-4/12) save irfn(Mean) r nograph}{p_end}

For the other moments of the distribution we use the command {cmd:qreg}:

{p 4 8 2}. {stata locproj y lr n ln l2n l3n, yl(3) sl(3) h(-4/12) m(qreg) q(20) nograph save irfn(Q20) vce(r)}{p_end}
{p 4 8 2}. {stata locproj y lr n ln l2n l3n, yl(3) sl(3) h(-4/12) m(qreg) q(50) nograph save irfn(Q50) vce(r)}{p_end}
{p 4 8 2}. {stata locproj y lr n ln l2n l3n, yl(3) sl(3) h(-4/12) m(qreg) q(80) nograph save irfn(Q80) vce(r)}{p_end}


{p}In all the cases we used the option "nograph" since we want to compare the four IRFs plotting them together in one graph 
using the command lpgraph. Therefore, we have also used the options save and ifrname to save the results of each LP into some
variables that we can use.{p_end}

{p}Now we can create one graph with the four IRFs plotted together, while also choosing the color of each one of the IRFs{p_end}

{p 4 8 2}. {stata lpgraph Mean Q20 Q50 Q80, h(-4/12) tti(Quarters) lab1(OLS) lab2(Low - Q20) lab3(Median) lab4(High - Q80) lc1(red) lc2(green) lc3(blue) lc4(brown) title(Example of qreg & lpgraph, size(0.9)) z}{p_end}

{p}We can also create four separate graphs and then combine them into a single one. For doing so, we need to specify the 
option {opt separate}. In this case, we are giving each separate graph a title, and therefore, we also specify the option nogelend. Additionally, we are choosing the color red for the IRFs lines of the four graphs:{p_end}

{p 4 8 2}. {stata lpgraph Mean Q20 Q50 Q80, h(-4/12) separate nolegend tti(Quarters) ti1(OLS) ti2(Low - Q20) ti3(Median) ti4(High - Q80) lcolor(red) title(Example of qreg & lpgraph, size(0.9)) z}{p_end}

{synopt :{helpb locproj##index:Return to Index}}{p_end}
{synoptline}


{marker example6}{...}
{title:Example 6. Examples using instrumental variables methods}

{p}We follow the example of the command {cmd ivlpirf} in the Stata 19.0 manual and we use data on U.S. industrial production 
growth ({bf:ip_growth}) and the interest rate ({bf:fedfunds}) to estimate the effects of an interest rate increase 
on economic activity.{p_end}

{p}Following the example, we are concerned that the change in {bf:fedfunds} is endogenous. We have available an instrument, 
{bf:money_inst}, that captures monetary shocks. It is correlated with change in {bf:fedfunds} but uncorrelated with any 
nonmonetary shocks. We use this variable as an instrument for the change in {bf:fedfunds}.{p_end}

{p}In the following equation locproj interprets that the shock variable is {bf:ip_growth} and we need to specify 
the instruments we want to use using the option {opt instr()}. Initially, we will only use the instrument {bf:money_inst}. 
We also need to specify which method we want to use through the option {opt met()}, which in this case is {cmd:ivregress gmm}. 
Notice that in this case the option {opt met()} should include the {opt gmm} sub-method.{p_end}

{p 4 8 2}. {stata use usmacro3.dta, clear}{p_end}

Or:
{p 4 8 0}. {stata webuse set www.stata-press.com/data/r18/}

{p 4 8 2}. {stata webuse usmacro3.dta, clear}{p_end}

{p 4 8 2}. {stata locproj ip_growth d.fedfunds, h(4) yl(2) sl(2) m(ivregress gmm) instr(money_inst)}{p_end}

{p}If we have more available instruments we should include them in the option {opt instr()}. For example, we can also 
include the instrument variable {bf:oil_instr}. If our estimation method is ivregress we can test whether we have 
overidentification at every step of the LP. This can be done by using the option {opt ivtest()}, which performs and displays one of
the three postestimation tests available after using the {cmd:command ivregress}, for each step/horizon. 
For testing overindentifying restrictions we need to use the suboption {opt overid} inside the option {opt ivtest()}.{p_end}

{p 4 8 2}. {stata locproj ip_growth d.fedfunds, ivtest(overid) instr(money_inst oil_inst) h(4) yl(2) sl(2) m(ivregress gmm)}{p_end}

{p}We can also use the suboption {opt endogenous} in {opt ivtest()} to perform tests to determine whether endogenous regressors in the model are in fact exogenous at every step:{p_end}

{p 4 8 2}. {stata locproj ip_growth d.fedfunds, instr(money_inst) ivtest(endogenous) h(4) yl(2) sl(2) m(ivregress gmm)}

{p}The suboption {it:firststage} is also available, which reports various statistics that measure the relevance of the excluded 
exogenous variables. {p_end}

{p}We can also use the command {cmd:ivqregress} if we want to use instrumental-variables quantile regression as our estimation method. 
In the same way as in the case of command {cmd:qreg}, we can specify lags of the dependent variable and the shock as options, 
but we cannot use time-series operators in the main syntax. Then we would first need to generate a new variable equal to the change 
in the fed funds rate, d.fedfunds. We also need to specify the sub-method in the option met together with the 
command {cmd:ivqregress}:{p_end}

{p 4 8 2}. {stata gen dfedfunds = d.fedfunds}{p_end}
{p 4 8 2}. {stata locproj ip_growth dfedfunds, h(4) yl(2) sl(2) m(ivqregress iqr) instr(money_inst)}{p_end}


{synopt :{helpb locproj##index:Return to Index}}{p_end}
{synoptline}


{marker example7}{...}
{title:Example 7. Non-linear effects, interactions and binary dependent variable: Using the option {opt margins}}

{p}We need to use the JST database and merge it with the "RecessionDummies" datasets:{p_end}

{p 4 8 2}. {stata use JSTdatasetR5.dta, clear}{p_end}

Or
{p 4 8 2}. {stata webuse set data.macrohistory.net/JST/}

{p 4 8 2}. {stata webuse JSTdatasetR5.dta, clear}{p_end}

{p 4 8 2}. {cmd: merge 1:1 year iso using "RecessionDummies.dta", nogen}{p_end}
{p 4 8 2}. {stata xtset ifs year}{p_end}

We also need to drop WWI and WWII years from JST dataset:

{p 4 8 2}. {stata drop if year >=1914 & year <=1919}{p_end}
{p 4 8 2}. {stata drop if year >=1939 & year <=1947}{p_end}

{p}In our first example, we will estimate the IRF of the probability of a banking crisis to an increase in the USA short-term interest rate. 
Our dependent variable in this case is the dummy variable {bf:crisisJST} that is equal to 1 for banking crises.{p_end}

{p}We need to generate a new variable {bf:stir_us} with the US interest rate as a common variable for all the countries in the sample, in order
to estimate the response of the probability of a banking crisis to the short-term interest rate in the US:{p_end}

{p 4 8 2}. {stata gen stir_us0=stir if iso=="USA"}{p_end}
{p 4 8 2}. {stata egen stir_us=mean(stir_us0), by(year)}{p_end}

{p}Now we are going to estimate the IRF using the option {opt margins}. The option {opt margins} estimates the marginal effect of a unit of
our shock variable (stir_us) on the probability of a banking crisis, which is our dependent (response) variable. 
We are using as estimation method the command {cmd:xtlogit} with fixed effects:{p_end}

{p 4 8 2}. {stata locproj crisisJST l(0/2).stir_us, margins m(xtlogit) fe}{p_end}

{p}We can also interact the shock variable with a dummy variable, for instance, whether a country has a "PEG" 
foreign exchange regime.{p_end}

{p}The option margins allow us to estimate a separate IRF for each category of the dummy variable PEG. For doing that we need to use the 
option {opt mrfvar()}. In this option we need to specify the expansion of the categorical variable that has been interacted 
with our shock variable.{p_end}

{p}We also need to use the explicit option to define which variable is our shock without any interaction term, since the command 
{cmd:margins} does not accept an interaction term expression in its {bf:dydx()} option: {p_end}

{p 4 8 2}. {stata locproj crisisJST peg#c.l(0/2).stir_us, s(stir_us) margins m(xtlogit) fe mrfvar(1.peg)}{p_end}
{p 4 8 2}. {stata locproj crisisJST peg#c.l(0/2).stir_us, s(stir_us) margins m(xtlogit) fe mrfvar(0.peg)}{p_end}

{p}Alternatively, instead of entering the shock variable as {bf:peg#c.l(0/2).stir_us} in the main syntax, we can enter the expression 
{bf:l(0/2).stir_us peg#c.l(0/2).stir_us} and in this way the command would use the variable {bf:stir_us} as the shock variable, 
whithout the need to specify it through the {cmd:locproj} option {opt shock()}:{p_end}

{p 4 8 2}. {stata locproj crisisJST l(0/2).stir_us peg#c.l(0/2).stir_us, margins m(xtlogit) fe mrfvar(1.peg)}{p_end}
{p 4 8 2}. {stata locproj crisisJST l(0/2).stir_us peg#c.l(0/2).stir_us, margins m(xtlogit) fe mrfvar(0.peg)}{p_end}

{synopt :{helpb locproj##index:Return to Index}}{p_end}
{synoptline}


{marker example8}{...}
{title:Example 8. D-i-D Event Study}

{p}We can use {cmd:locproj} to estimate an Event Study based on the DiD estimator in the case where the treatment period is the same 
for all treated individuals.{p_end}

{p}In this example, we have a dataset that contains a response variable {bf:y} and a variable {bf:d} that is equal to one for a subset of individuals who were all treated in the year 2004. The dataset also contains a set of dummy variables 
{it:f01}, {it:f02},..., {it:f06} that are equal to one for the years 2001 to 2006 respectively.{p_end}

{p}Following Wooldridge (2021) we can estimate the Event Study regression without covariates using the following specification:{p_end}

{p 4 8 2}. {stata use did_common_6, clear}{p_end}
{p 4 8 2}. {stata xtset id year}{p_end}
{p 4 8 2}. {stata reg y c.d#c.f01 c.d#c.f02 c.d#c.f04 c.d#c.f05 c.d#c.f06 d i.year, vce(cluster id)}{p_end}

{p}All effects are measured relative to the period just before intervention, i.e. 2003. The event-study coefficients are thus 
{bf:-0.551, -.342, 0, 3.177, 4.894, 5.839}. {p_end}

{p}We can reproduce these results with {cmd:locproj}. We need to use the option {opt transf(cmlt)} in order to obtain 
the long-term differencing. We need to define the horizon period as hor(-3/2) since the coefficient of the period {it:h = −1} 
is normalized to zero and we want to evaluate two periods before the intervention {it:h = −3, −2} and three periods 
after the intervention {it:h = 0, 1, 2}. {p_end}

{p}We also need to have a variable that is equal to one only for treated individuals and only after the intervention, i.e. from 2004 onward, which we are going to call treat. Our shock variable is the change in this new variable d.treat:{p_end}

{p 4 8 2}. {stata gen treat=year>=2004 & d}{p_end}
{p 4 8 2}. {stata locproj y d.treat i.year, tr(cmlt) vce(cluster id) h(-3/2) z gropt(xline(-1, lc(gray)))}{p_end}


{synoptline}

{title:References}

{p}Jordà, Òscar. 2005, "Estimation and inference of impulse responses by local projections." American Economic Review 95, no. 1 (2005): 161-182."{p_end}

{p}Wooldridge, J. M., 2021, "Two-way fixed effects, the two-way mundlak regression, and difference-in-differences estimators". Available at SSRN 3906345{p_end}

{p}Jordà, Ò. and Taylor, A.M. 2024, "Local Projections". Federal Reserve Bank of San Francisco Working Paper Series 2024(24){p_end}

{p}https://sites.google.com/site/oscarjorda/home/local-projections?pli=1{p_end}

{synoptline}

{marker acknowledgements}{...}
{title:Acknowledgements}
{pstd}I am grateful to Enrique Pinzon (StataCorp) for its useful comments and suggestions at the US Stata Conference 2023.{p_end}

{synoptline}

{p}If you use this package, please cite both the package and the paper introducing it:{p_end}

{p}Ugarte-Ruiz, A. 2023. "LOCPROJ: Stata module to estimate Local Projections," Statistical Software Components S459204, Boston College Department of Economics{p_end}
{p}Ugarte-Ruiz, A. 2025., "LOCPROJ & LPGRAPH: Stata commands to estimate Local Projections". BBVA-Research WP-09, July 2025{p_end}

{synoptline}

{title:Author}

Alfonso Ugarte-Ruiz
alfonso.ugarte@bbva.com
