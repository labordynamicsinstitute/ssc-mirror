{smcl}
{* First Version May 10 2023}{...}
{* This Version May 10 2023}{...}
{viewerdialog locproj "dialog locproj"}{...}
{vieweralsosee "[L] lincom" "help lincom"}{...}
{vieweralsosee "[M] margins" "help margins"}{...}
{hline}
Help for {hi:locproj}
{hline}

{title:Description}

{p}{cmd:locproj} estimates linear and non-linear Impulse Response Functions (IRF) based on the local projections methodology first proposed by Jordà (2005). 
The procedure allows easily implementation of several options used in the growing literature of local projections. {p_end}

{p}It generates temporary variables with the necessary transformations of the response variable in order to estimate the IRF 
in the desired transformation option, such as levels, logs, differences, log-differences, cumulative changes or cumulative log-differences. 
For every option, the procedure also generates temporary variables with the corresponding transformation of the dependent variable 
needed in case the user wants to include lags of the dependent variable that are consistent with the chosen transformation.{p_end}
 
{p}{cmd:locproj} allows the user to choose different estimation methods for both time series and panel data, including some instrumental variables methods 
currently available in Stata such as {cmd:ivregress} or {cmd:xtivreg}.{p_end}

{p}{cmd:locproj} reports the IRF, together with its standard error and confidence interval, as an output matrix and through an IRF graph. 
The user can easily choose different options for the desired IRF graph, as well as other options to save and use the results.{p_end}

{p}The options allow defining the desired specification in a fully automatic or in a more explicit way, with many alternatives in between. {p_end}

{p}If the user chooses the automatic specification, the syntax is very close to a typical regression command in Stata, 
with the only restriction that {cmd:locproj} interprets the variable that corresponds to the shock (impulse) as the one just after 
the dependent variable or its lagged terms, and only that one variable represents the shock. {p_end}

{p}Alternatively, the user can choose to explicitly define the shock variable (or variables), the number of lags of the shock, the number of lags 
of the dependent variable, and the control variables. As mentioned before, the user can play with alternatives between the 
fully automatic or the fully explicit, depending on which option is easier or more convenient to use.{p_end}

{p}The explicit option is recommended when the shock should include more than one variable, for instance, an additional non-linear term, 
or an interaction with another variable.{p_end}

{p}{cmd:locproj} uses the Stata command {cmd:lincom} to estimate the response to the shock variable or variables, allowing to estimate responses to linear
combinations of variables, including interactions with factor or continuous variables. Importantly, it also allows the use of marginal effects instead of 
regression coefficients, which is highly convenient when the response variable is binary and the user wants to estimate the response as a probability.
In the latter case, {cmd:locproj} makes use of the Stata command {cmd:margins}, which could further facilitate the estimation of responses when 
the shock corresponds to an interaction of variables (factor or continuous) instead of just a single variable.{p_end}

{p}{cmd:locproj} also allows different options regarding the horizon and the response starting period. For instance, it automatically adjusts 
the horizon in the case that the shock variable(s) is included with a lag and no contemporaneous term, e.g. {it:L.shockvar}, in which case 
the response at {it:hor = 0} would be equal to 0 and an extra period will be added to final horizon period. {p_end}


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
{cmd:,}
[ {opt h:or(numlist integer)} {opt lcs(string)} {opt lco:pt(string)} {opt fc:ontrols(varlist)} {opt ins:tr(string)} {opt tr:ansf(string)} 
{opt m:et(string)} {it:model_options} {opt hopt(string)} {opt conf(numlist integer)} {opt noi:sily} {opt save:irf} {opt irfn:ame(string)} 
{opt f:act(real)} {opt marg:ins} {opt mrfv:ar(varlist)} {opt mrpr:edict(string)} {opt mrgo:pt(string)} {opt nograph} {opt ti:tle(string)} 
{opt lab:el(string)} {opt z:ero} {opt lcol:or(string)} {opt tti:tle(string)} {opt grn:ame(string)} {opt grs:ave(string)} 
{opt as(string)} {opt gro:pt(string)}  ]{p_end}
	

{pstd}
Explicit Specification (Shock and Lags)

{p 8 13 2}
{cmd:locproj}
{depvar}
{ifin}
{cmd:,}
[ {opt h:or(numlist integer)} {opt s:hock(varlist)} {opt c:ontrols(varlist)} {opt yl:ags(integer)} {opt sl:ags(integer)} {opt lcs(string)} 
{opt lco:pt(string)} {opt fc:ontrols(varlist)} {opt ins:tr(string)} {opt tr:ansf(string)} {opt m:et(string)} {it:model_options} {opt hopt(string)} 
{opt conf(numlist integer)} {opt noi:sily} {opt save:irf} {opt irfn:ame(string)} {opt f:act(real)} {opt marg:ins} {opt mrfv:ar(varlist)} 
{opt mrpr:edict(string)} {opt mrgo:pt(string)} {opt nograph} {opt ti:tle(string)} {opt lab:el(string)} {opt z:ero} {opt lcol:or(string)} 
{opt tti:tle(string)} {opt grn:ame(string)} {opt grs:ave(string)} {opt as(string)} {opt gro:pt(string)} ]{p_end}



{synoptset 33 tabbed}{...}
{marker Options}{...}
{synopthdr:Options}
{synoptline}

{syntab:{bf:Model Specification:}}

{synopt:{opt h:or(numlist/integer)}}Specifies the number of steps or horizon length for the IRF. 
It can be specified either as a range (e.g. {it:hor(0/6)} or {it:hor(1/6)}), or just as the final horizon period (e.g. {it:hor(6)}) 
in which case the command assumes the horizon starts at period 0 and ends in period 6. The default horizon range is {it:hor = 0,...,5} 
if nothing is specified.{p_end}

{synopt:{opt s:hock(varlist)}}Allows to explicitly define the variable or variables that represent the shock or impulse that 
will generate the response and the IRF. If this option is not specified the command will automatically choose the first variable that 
is inmmediately after the {depvar} and its lagged terms if they are included in the main {it:varlist}.
This option should be used when the desired shock includes more than one variable, for instance a non-linear term or 
an interaction term.{p_end}

{synopt:{opt lcs(string)}}Specifies an expression, usually an addition of variables, that defines a linear combination of variables that represents 
the desired impulse (shock).  This option should be used when the desired shock includes more than one variable and the name of one of them 
is not explictily included in the syntax variable list, for instance the constant term ({it:_cons}), or the expansion of an expression that
includes factor variable terms, e.g. {it:12.code#c.xvar}. The expression that should go inside the parenthesis is analogous to any expression 
that is tested using the commands {cmd:lincom} or {cmd:test}.{p_end}

{synopt:{opt sl:ags(integer)}}Specifies explicitly the number of lags of the shock variable or variables that should be included in the specification.
The lagged terms of the shock could also be included directly in the main {it:varlist} next to the first variable that represents the shock.
If more than one variable is specified through the option {opt s:hock()} then the specification will include lags of all of them.{p_end}

{synopt:{opt yl:ags(integer)}}Specifies explicitly the number of lags of the {depvar} that should be included in the specification. 
The way the lags of the dependent variable are included changes depending on the type of tranformation that is defined by the user 
through the option {opt tr:ansf()}.{p_end}

{synopt:{opt c:ontrols(varlist)}}Allows to explicitly define the variable or variables that represent the control variables. 
If this option is not specified the command simply includes all the variables that are inmmediately after the shock variable(s) 
and its lagged terms if they are included in the main {it:varlist}. 
The control variables could include any number of lags, interactions, or any other desired transformations.{p_end}

{synopt:{opt fc:ontrols(varlist)}}Specifies any control variable(s) that should be included at the same horizon as the IRF, 
i.e. that their forecast should be included depending on the horizon, i.e. {it:fcontrol(t+h)} with {it:h = 0...hor}.{p_end}

{synopt:{opt lco:pt(string)}}Specifies any option available in the command {cmd:lincom}. See {help lincom} for specific help about 
the command {cmd:lincom}{p_end}


{syntab:{bf:Marginal Effect Options:}}

{synopt:{opt marg:ins}}Specifies that the marginal effect of the shock variable is used instead of the regression coefficients. 
For simplicity, it only allows using the dydx option of the command {cmd:margins}. See {help margins} for specific help about 
the command {cmd:margins}{p_end}

{synopt:{opt mrfv:ar(varlist)}}Specifies the factor or continuous variable that it is interacted with the shock variable in the specification.
This option should be used together with the {opt s:hock(varlist)} option and the {opt marg:ins} option.{p_end} 

{synopt:{opt mrpr:ed(string)}}Specifies the option to be used with the predict command to produce the variable that will be used as the response 
when using the {opt marg:ins} option, e.g. {it:pr}, {it:pc1}, {it:pu0}, {it:xb}. It this option is not specified it uses the default option of the estimation method being used.{p_end}

{synopt:{opt mro:pt(string)}}Allows to specify other options available in the command {cmd: margins} that have not been specified in the previous marginal effect options. 
 See {help margins} for specific help about using the command {cmd:margins}.{p_end}


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


{synopt:{it:model_options}}Specifies any other estimation options specific to the method used and not defined elsewhere. 
If the user wants to specify any methodological option corresponding to the estimation method being used, she only has to 
include them alongside the rest of {cmd:locproj} options.{p_end}

{synopt:{opt hopt(string)}}Specifies any methodological option that depends directly on the horizon of the IRF, i.e. any option 
that must change with every step/horizon of the IRF {it:h = 0...hor}.{p_end}

{synopt:{opt noi:sily}}If this option is specified, the command displays a regression output for each one of the horizons. If this option 
is not specified the command only returns a matrix with the IRF, its standard error and the confidence bands. {p_end}


{syntab:{bf:IRF Options:}}

{synopt:{opt conf(numlist)}}Specifies one or (max) two confidence levels for calculating the confidence bands. The default is 95%. {p_end}

{synopt:{opt save:irf}}If this option is specified, the IRF, its standard error and the confidence bands are saved as new variables, otherwise 
no new variables are created. If this option is specified, the command assigns a default name to the new generated variables.{p_end}

{synopt:{opt irfn:ame(string)}}Specifies a name/prefix for the new IRF variable and the other new generated variables (standard error 
and confidence bands).{p_end}

{synopt:{opt f:act(real)}}Specifies a factor for scaling the IRF, for instance, if the user wants to express the log difference transformation 
in percentage terms, this option should be specified as fact(100).{p_end}


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

{synoptline}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:locproj} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{bf:r(irf)}}A matrix including the Impulse Response Function (IRF), its standard error and its confidence interval.{p_end}

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

{title:Example 1. Use of {cmd:locproj} to replicate the IRFs in the "simple time series example: lp-example" do-file in Jordà website }

(https://sites.google.com/site/oscarjorda/home/local-projections?pli=1)

{p 4 8 2}{cmd:. use AED_INTERESTRATES.dta}{p_end}

{title:Example 1.1 Defining the basic specific options}

{p}What the automatic vs. explicit specification means is that the user can let {cmd:locproj} interpret  in an automatic way
which variables in the provided {it:varlist} correspond to the dependent variable, which one is the shock, 
which ones are control variables, and also which ones are just lags of each type of variable. Alternatively,
in more complicated cases, the user can specify all those details in a explicit way using the available options for 
such cases.{p_end}

{p}The simplest local projection specification in which the response variable is gs10 and the shock variable is gs1 would be 
(automatic specification):{p_end}

{p 4 8 2}{cmd:. locproj gs10 gs1}{p_end}

Which would also be equivalent to the following (explicit specification):

{p 4 8 2}{cmd:. locproj gs10, shock(gs1)}{p_end}

A more interesting specification would include lags of the dependent variable and of the shock, and would specify a response horizon. 
All the next six examples do those things and are exactly equivalent:

{p}{it: Automatic specification}

{p 4 8 2}{cmd:. locproj gs10 l(0/4).gs1 l(1/3).gs10, hor(12)}{p_end}
{p 4 8 2}{cmd:. locproj l(0/3).gs10 l(0/4).gs1, hor(12)}{p_end}
{p 4 8 2}{cmd:. locproj gs10 l(1/3).gs10 l(0/4).gs1, hor(12)}{p_end}

{p}{it: Explicit or intermmediate specification}

{p 4 8 2}{cmd:. locproj gs10, shock(gs1) ylags(3) slags(4) hor(12)}{p_end}
{p 4 8 2}{cmd:. locproj gs10 l(1/3).gs10, shock(gs1) slags(4) hor(12)}{p_end}
{p 4 8 2}{cmd:. locproj gs10 l(0/4).gs1, ylags(3) hor(12)}{p_end}

{title:Example 1.2. A simple non-linear example}

If we want to specify a very simple non-linear shock, for instance, a quadratic term of the variable {bf:gs1}, we only need to add 
such additional variable in the {opt shock()} option:

{p 4 8 2}{cmd:. gen gs1_2 = gs1^2}{p_end}

{p 4 8 2}{cmd:. locproj gs10, shock(gs1 gs1_2) ylags(3) slags(4) hor(12)}{p_end}

{cmd:locproj} will take all the variables that are defined in the {opt shock()} option and the resulting IRF will correspond to the 
addition of the individual effect of those variables, for instance, in this example, the IRF would be the addition of the estimated
coefficients of the variables {bf:gs1} and {bf:gs1_2}.


{title:Example 1.3. Estimation method options}

The Jordà example requires using Newey-West as the estimation method, which consequently requires specifying that the option
"lag" in the Newey-West command should depend on the horizon of the IRF in the following way:

{p 4 8 2}{cmd:. locproj gs10 l(0/4).gs1 l(1/3).gs10, h(12) met(newey) hopt(lag)}{p_end}


{title:Example 1.4. Displaying all the regression outputs}

If we want to take a look at the regression output for each one of the horizons of the IRF we can use the option noisily. The regression
outputs displayed are not the direct outputs from whatever estimation method we are using, but a simplified output table. 
The reason for this is that {cmd: locproj} uses temporary variables whose given names do not have any meaning and would be difficult to 
understand. {cmd: locproj} generates a new output table with variable names related to the variable list defined by the user. 

{p 4 8 2}{cmd:. locproj gs10 l(0/4).dgs1, h(12) m(newey) hopt(lag) tr(cmlt) yl(3) noisily}{p_end}


{title:Example 1.5. Use of the transformation options}

{p}If we want to run the LP in differences (without using the already existing variables) we can use the option {bf:transf()}
together with the {bf:ylags()} option to define the number of lags of the dependent variable (notice that in this first
example we are also differentiating the shock variable gs1):{p_end}

{p 4 8 2}{cmd:. locproj gs10 l(0/4).d.gs1, h(12) m(newey) hopt(lag) transf(diff) yl(3)}{p_end}

{p}Alternatively, the model in differences using the already differentiated variables in the dataset without using
the transformation option would be:{p_end}

{p 4 8 2}{cmd:. locproj dgs10 l(0/4).dgs1 l(1/3).dgs10, hor(12) met(newey) hopt(lag)}{p_end}

{p}In the case of running the LP in cumulative differences we would have to use the option {bf:transf(cmlt)}, again, together with
the {bf:ylags()} option:{p_end}

{p 4 8 2}{cmd:. locproj gs10 l(0/4).d.gs1, h(12) m(newey) hopt(lag) tr(cmlt) yl(3)}{p_end}

{p}In the next examples we use the transformation in difference of logarithm and cumulative log-differences. 
In order to express the result in percentage terms, we also make use of the option {bf:fact()} and we scale the response 
by a factor of 100. We are going to estimate the IRF of a shock of the variable {bf:aaa} into the variable
{bf:baa}:{p_end}

{p 4 8 2}{cmd:. gen lnaaa = ln(aaa)}{p_end}

{bf:log-differences:}

{p 4 8 2}{cmd:. locproj baa l(0/4).lnaaa, h(12) m(newey) hopt(lag) transf(logs diff) yl(3) fact(100)}{p_end}

{bf:cumulative log-differences:}

{p 4 8 2}{cmd:. locproj baa l(0/4).lnaaa, h(12) m(newey) hopt(lag) transf(logs cmlt) yl(3) fact(100)}{p_end}


{title:Example 1.6. Changing the confidence level or using more than one level}

By default the confidence level for the confidence bands is 95%. If we want to change it, we can use the {opt conf()} option
which admits a maximum of two levels and only admits integer values:

{p 4 8 2}{cmd:. locproj gs10 l(0/4).dgs1, h(12) m(newey) hopt(lag) tr(diff) yl(3) conf(90)}{p_end}

{p 4 8 2}{cmd:. locproj gs10 l(0/4).dgs1, h(12) m(newey) hopt(lag) tr(diff) yl(3) conf(66 99)}{p_end}


{title:Example 1.7. Saving the IRF results into new variables}

{p}If we want to save the estimated IRF into a new variable that can be used later, we can use it through the options {bf:saveirf} and {bf:irfname()}.
If we just type {bf:saveirf}, {cmd: locproj} generates four (or six) new variables with the IRF, its standard error and the confidence bands.
{cmd:locproj} uses some predetermined default names to save the corresponding variables (_irf, _seirf, _irf_lo and _irf_up), but if we want 
to give them a name of our preference (e.g. {it:newirf}), we can do it through the option {bf:irfname()}:{p_end}

{p 4 8 2}{cmd:. locproj gs10 l(0/4).dgs1, h(12) m(newey) hopt(lag) tr(diff) yl(3) saveirf}{p_end}

{p 4 8 2}{cmd:. locproj gs10 l(0/4).dgs1, h(12) m(newey) hopt(lag) tr(diff) yl(3) save irfname({it:newirf}) }{p_end}


{title:Example 1.8. Some graph options}

If we do not want {cmd:locproj} to produce a graph, we just have to type {bf:nograph}:

{p 4 8 2}{cmd:. locproj gs10 l(0/4).dgs1, h(12) m(newey) hopt(lag) tr(diff) yl(3) nograph}{p_end}

{p}In the following example we are going to produce a graph in which a dashed-line with the value of zero is included, we are goint to give 
the graph the tittle "LP Example", include a label "1 Year Treasury IRF", change the color of the IRF line and its confidence interval 
to red instead of blue, and define the time axis as "Number of Days":{p_end}

{p 4 8 2}{cmd:. locproj gs10 l(0/4).dgs1, h(12) m(newey) hopt(lag) tr(diff) yl(3) zero title("LP Example") label("1 Year Treasury IRF") lcolor(red) ttitle("Number of Days") conf(66 95)}{p_end}

Next, we are going to give the graph a name, we are going to save it in a folder in our disk as a png file named "example1":

{p 4 8 2}{cmd:. locproj gs10 l(0/4).dgs1, h(12) m(newey) hopt(lag) tr(diff) yl(3) zero title(LP Example) grname(Example1) grsave(C:\Documents\example1.png) as(png)}{p_end}

{p}We can also add other graph options inside the {opt gropt()} option, for instance, we can define the labels of the y-axis and change the 
background color to white:{p_end}

{p 4 8 2}{cmd:. locproj gs10 l(0/4).dgs1, h(12) m(newey) hopt(lag) tr(diff) yl(3) zero title(LP Example) gropt(graphregion(fcolor(white)) ylabel(-0.25(0.25)1))}{p_end}

{synoptline}

{title:Example 2. Use of {cmd:locproj} to replicate the IRFs in the "panel data example: lp_example_panel" do-file in Jordà website}

{p 4 8 2}{cmd:. use "http://data.macrohistory.net/JST/JSTdatasetR5.dta"}{p_end}

For reproducing the first example in the Panel data example in Jordà website, we first need to generate some variables:

{p 4 8 2}{cmd:. gen lgdpr = 100*ln(rgdppc*pop)}{p_end}
{p 4 8 2}{cmd:. gen lcpi = 100*ln(cpi)}{p_end}
{p 4 8 2}{cmd:. gen dlgdpr = d.lgdpr}{p_end}
{p 4 8 2}{cmd:. gen dstir = d.stir}{p_end}

{p}Now, we can reproduce the response of real GDP to a 1pp shock to the real short-term interest rate. The next five examples are exactly equivalent. 
They differ in how to define the shock variable and its lags, and the dependent variable and its lags. In all of them, the estimation method is {cmd:xtreg}, 
they use the "fixed-effect" estimator and a cluster-robust covariance matrix. They use a confidence level of 90%. They define the values of the y-axis, 
they y-axis title, the x-axis label and the title of the graph:{p_end}

{it:Using the transformation option transf() and the fully explicit options:}
{p 4 8 2}{cmd:. locproj lgdpr, s(l.d.stir) c(l(1/3).d.lcpi) tr(diff) h(4) yl(3) sl(3) fe cluster(iso) z conf(90) gropt(ylabel(-0.4(0.2)0.2) ytitle(Percent)) tti(Year) title(Response of GDPR to 1pp shock to STIR (Cholesky))}{p_end}

{it:Using the existing differentiated variables and a fully automatic specification:}
{p 4 8 2}{cmd:. locproj l(0/3).dlgdpr l(1/3).dstir l(1/3).d.lcpi, fe cluster(iso) h(4) z conf(90) gropt(ylabel(-0.4(0.2)0.2) ytitle(Percent)) tti(Year) title(Response of GDPR to 1pp shock to STIR (Cholesky))}{p_end}

{it:Directly differentiating the dependent variable and explicit options for the shock and control variables:}
{p 4 8 2}{cmd:. locproj l(0/3).d.lgdpr, s(l.d.stir) sl(3) c(l(1/3).d.lcpi) fe cluster(iso) h(4) z conf(90) gropt(ylabel(-0.4(0.2)0.2) ytitle(Percent)) tti(Year) title(Response of GDPR to 1pp shock to STIR (Cholesky))}{p_end}

{it:Using the transformation option transf() and the fully automatic options:}
{p 4 8 2}{cmd:. locproj l(0/3).lgdpr l(1/3).d.stir l(1/3).d.lcpi, fe cluster(iso) tr(diff) h(4) z conf(90) gropt(ylabel(-0.4(0.2)0.2) ytitle(Percent)) tti(Year) title(Response of GDPR to 1pp shock to STIR (Cholesky))}{p_end}

{it:Using the transformation option transf() and a combination of automatic and explicit options:}
{p 4 8 2}{cmd:. locproj lgdpr l.d.stir l(1/3).d.lcpi, h(4) yl(3) sl(3) fe cluster(iso) tr(diff) z conf(90) gropt(ylabel(-0.4(0.2)0.2) ytitle(Percent)) tti(Year) title(Response of GDPR to 1pp shock to STIR (Cholesky))}{p_end}

{p}In all the previous equivalent five examples, the shock variable is included with a lag and no contemporaneous term (L.D.stir), and thus, the response at {it:hor = 0} is equal to 0 and an extra period is added to 
the final horizon period.{p_end}


{p}Alternatively, in the next example, when estimating the response of CPI to the short-term interest rate, we just need to change the dependent variable to cpi instead of gdpr in any of the previous examples. We also need to change the number of lags of the control variable, which in this case is the GDP, from 
(0/3) to (1/3) in order to specify a Cholesky decomposition.{p_end}

{p 4 8 2}{cmd:. locproj lcpi, s(l.d.stir) c(l(0/3).d.lgdpr) tr(diff) h(4) yl(3) sl(3) fe cluster(iso) z conf(90) gropt(ylabel(-0.4(0.2)0.2) ytitle(Percent)) tti(Year) title(Response of CPI to 1pp shock to STIR (Cholesky))}{p_end}


{p}Finally, in the final exercise, the shock variable is the same as the dependent variable, so it is more convenient to use an explicit option 
for the shock and its lags.Moreover, the first response at {it:hor = 0} is equal to 1 since the response variable and the shock are the same
at that horizon period.{p_end}

{p 4 8 2}{cmd:. locproj d.stir l(0/3).d.lcpi l(0/3).d.lgdpr, s(d.stir) sl(3) h(4) fe cluster(iso) z conf(90) gropt(ylabel(-0.4(0.2)0.2) ytitle(Percent)) tti(Year) title(Response of GDPR to 1pp shock to STIR (Cholesky))}{p_end}


{synoptline}

{title:Example 3. Use of {cmd:locproj} to replicate the IRFs in the "LPIV example: lpiv_example" do-file in Jordà website}

For this example we use the databases RR_monetary_shock_quarterly.dta and lpiv_15Mar2022.dta from Jordà website.

{p 4 8 2}{cmd:. use RR_monetary_shock_quarterly.dta}{p_end}
{p 4 8 2}{cmd:. merge 1:1 date using lpiv_15Mar2022.dta, nogen}{p_end}

Next, we keep only nonmissing observations in resid_full i.e. 1969m1 - 2007m12

{p 4 8 2}{cmd:. keep if resid_full != .}{p_end}

We need to declare the time series variable

{p 4 8 2}{cmd:. tsset date}{p_end}

{p}For estimating the IRF using OLS we need to take into consideration that in the example, the response horizon starts at {it:hor = 1}. However, for exactly replicating the example, we need to use the one-step ahead 
forecast of UNRATE as the dependent variable instead of UNRATE. We also use Newey-West as the variance-covariance estimation method, which requires defining the option {opt lag()} in Newey-West, and thus, we need to use the option
{opt hopt()} in our {cmd:locproj} command:

{p 4 8 2}{cmd:. locproj f.UNRATE DFF l(1/4).DFF l(1/4).UNRATE, h(0/15) hopt(lag) m(newey) z}{p_end}

{p}For replicating the instrumental variable IRF example, we use the option {opt met()} specifying that the method is {it:ivregress gmm}. Notice that in this case the {opt meth()} option should include the {it:gmm} sub-method.
Additionally, we need to define the instrument(s) for the shock, which in this case corresponds to the variable {it:resid_full}. Moreover, we define as an estimation method option the variance-covariance estimator {it: hac nwest} in the following way:{p_end}

{p 4 8 2}{cmd:. locproj f.UNRATE l(0/4).DFF l(1/4).UNRATE, h(0/15) met(ivregress gmm) instr(resid_full) vce(hac nwest) z}{p_end}

{p}In this particular case, if we want to replicate the Jordà example using the {opt ylags()} option would be a bit tricky, since the dependent variable 
is {bf:f.UNRATE}, but the lags of the variable {bf:UNRATE} in the original specification are {bf:(1/4)}. 
If we were to specify {opt ylags(4)} then we would actually be including lags {bf:(0/3)} 
given the forecast of the dependent variable. Therefore, in this case, it would be more convenient to include the lags of the variable {bf:UNRATE} 
in the main {it:varlist} or even as control variables with the option {opt controls()}:{p_end}

{p 4 8 2}{cmd:. locproj f.UNRATE l(1/4).UNRATE, s(DFF) sl(4) h(0/15) met(ivregress gmm) instr(resid_full) vce(hac nwest) z}{p_end}

{p 4 8 2}{cmd:. locproj f.UNRATE, s(DFF) sl(4) controls(l(1/4).UNRATE) h(0/15) met(ivregress gmm) instr(resid_full) vce(hac nwest) z}{p_end}


{synoptline}

{title:Example 4. Non-linear effects and interactions: Using the option {opt lcs()}}

{p}For Examples 4 and 5 we are going to use need the JST dataset and the "RecessionDummies" dataset that contains data on recessions and financial crises.{p_end}

{p 4 8 2}{cmd:. use "http://data.macrohistory.net/JST/JSTdatasetR5.dta"}{p_end}

{p 4 8 2}{cmd:. merge 1:1 year iso using "RecessionDummies.dta", nogen}{p_end}

We need to declare the panel data variables:

{p 4 8 2}{cmd:. xtset ifs year}{p_end}

We also need to drop WWI and WWII years from JST dataset:

{p 4 8 2}{cmd:. drop if year >=1914 & year <=1919}{p_end}
{p 4 8 2}{cmd:. drop if year >=1939 & year <=1947}{p_end}

{p}In the "RecessionDummies" database, the variable {bf:F} is a Financial Crisis dummy variable, while the variable {bf:N} is a Normal Recession dummy variable. 
In this example we want to look at the cumulative IRF of real GDP per capita to a financial crisis, while controling for the effect of normal recessions, 
and viceversa. Thus, we need to use the option {opt lcs()} since the effect we are looking for is the sum of the constant term plus the effect of 
{bf:F=1} or {bf:N=1}.{p_end}

{p}Therefore, in the following examples we include the expression "_cons + l.F" and "_cons + l.N" inside the option {opt lcs()}. Notice that when we use
the option {opt lcs()} the order of the variables l.F and l.N in the main syntax does not matter, since the shock that {cmd:locproj} evaluates 
is {bf:only determined} by what it is defined by the option {opt lcs()}:{p_end}

{p 4 8 2}{cmd:. locproj rgdppc l.F l.N, fe robust tr(logs cmlt) h(4) z f(100) lcs(_cons + l.F)}{p_end}

{p 4 8 2}{cmd:. locproj rgdppc l.F l.N, fe robust tr(logs cmlt) h(4) z f(100) lcs(_cons + l.N)}{p_end}

{p}We can include more complicated interactions, for instance we can interact the effect of Financial Crisis (F) or Normal Recessions (N) with the
public debt-to-GDP ratio and evaluate the IRF at different levels of such ratio.{p_end}

{p}We first estimate the mean and standard deviation of the Public Debt-to-GDP ratio:{p_end}

{p 4 8 2}{cmd:. sum debtgdp}{p_end}
{p 4 8 2}{cmd:. sca dm=r(mean)}{p_end}
{p 4 8 2}{cmd:. sca dsd=r(sd)}{p_end}

{p}In the command syntax we include the interaction of the public debt ratio with the financial crises and the normal recessions. Then in the {opt lcs()}
we enter the expansion of the interaction between financial crises and the debt ratio {bf:(1.l.F#c.l.debtgdp)}, multiplied by the mean and std. deviaton of
the ratio {bf:(dm+dsd)}:{p_end}

{p 4 8 2}{cmd:. locproj rgdppc l.N l.F l.(N#c.debtgdp F#c.debtgdp), fe robust tr(logs cmlt) nograph f(100) lcs(_cons+l.F+1.l.F#c.l.debtgdp*(dm+dsd))}{p_end}

{p}In a similar way for normal recessions:{p_end}

{p 4 8 2}{cmd:. locproj rgdppc l.N l.F l.(N#c.debtgdp F#c.debtgdp), fe robust tr(logs cmlt) nograph f(100) lcs(_cons+l.F+1.l.F#c.l.debtgdp*(dm+dsd))}{p_end}


{synoptline}

{title:Example 5. Non-linear effects, interactions and binary dependent variable: Using the option {opt margins}}

{p}We need again the JST and the "RecessionDummies" datasets:{p_end}

{p 4 8 2}{cmd:. use "http://data.macrohistory.net/JST/JSTdatasetR5.dta"}{p_end}
{p 4 8 2}{cmd:. merge 1:1 year iso using "RecessionDummies.dta", nogen}{p_end}
{p 4 8 2}{cmd:. xtset ifs year}{p_end}

We also need to drop WWI and WWII years from JST dataset:

{p 4 8 2}{cmd:. drop if year >=1914 & year <=1919}{p_end}
{p 4 8 2}{cmd:. drop if year >=1939 & year <=1947}{p_end}

{p}In our first example, we will estimate the IRF of the probability of a banking crisis to an increase in the USA short-term interest rate. 
Our dependent variable in this case is the dummy variable {bf:crisisJST} that is equal to 1 for banking crises.

We need to generate a new variable {bf:stir_us} with the US interest rate as a common variable for all the countries in the sample, in order
to estimate the response of the probability of a banking crisis to the short-term interest rate in the US:{p_end}

{p 4 8 2}{cmd:. gen stir_us0=stir if iso=="USA"}{p_end}
{p 4 8 2}{cmd:. egen stir_us=mean(stir_us0), by(year)}{p_end}

{p}Now we are going to estimate the IRF using the option {opt margins}. The option {opt margins} estimates the marginal effect of a unit of
our shock variable (stir_us) to the probability of a banking crisis, which is our dependent (response) variable. 
We are using as estimation method the command {cmd:xtlogit} with fixed effects:{p_end}

{p 4 8 2}{cmd:. locproj crisisJST l(0/2).stir_us, margins m(xtlogit) fe}{p_end}

{p}We can also interact the shock variable with a dummy variable, for instance, whether a country has a "PEG" foreign exchange regime.{p_end}

{p}The option margins allow us to estimate a separate IRF for each category of the dummy variable PEG. For doing that we need to use the option
{opt mrfvar()}. In this option we need to specify the expansion of the {bf:categorical variable that has been interacted with our shock variable}.
We also need to use the explicit option to define which variable is our shock without any interaction term, since the command {cmd:margins} 
does not accept an interaction term expression in its {bf:dydx()} option: {p_end}

{p 4 8 2}{cmd:. locproj crisisJST peg#c.l(0/2).stir_us, s(stir_us) margins m(xtlogit) fe mrfvar(1.peg)}{p_end}
{p 4 8 2}{cmd:. locproj crisisJST peg#c.l(0/2).stir_us, s(stir_us) margins m(xtlogit) fe mrfvar(0.peg)}{p_end}

{p}Alternatively, instead of entering the shock variable as {bf:peg#c.l(0/2).stir_us} in the main syntax, we can enter the expression 
{bf:l(0/2).stir_us peg#c.l(0/2).stir_us} and in this way the command would use the variable {bf:stir_us} as the shock variable, 
whithout the need to specify it through the {cmd:locproj} option {opt shock()}:{p_end}

{p 4 8 2}{cmd:. locproj crisisJST l(0/2).stir_us peg#c.l(0/2).stir_us, margins m(xtlogit) fe mrfvar(1.peg)}{p_end}
{p 4 8 2}{cmd:. locproj crisisJST l(0/2).stir_us peg#c.l(0/2).stir_us, margins m(xtlogit) fe mrfvar(0.peg)}{p_end}


{synoptline}

{title:References}

{p}"Jordà, Òscar. "Estimation and inference of impulse responses by local projections." American Economic Review 95, no. 1 (2005): 161-182."{p_end}
{p} https://sites.google.com/site/oscarjorda/home/local-projections?pli=1


{synoptline}

{title:Author}

Alfonso Ugarte-Ruiz
alfonso.ugarte@bbva.com
