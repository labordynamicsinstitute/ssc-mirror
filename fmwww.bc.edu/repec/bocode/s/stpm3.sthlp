{smcl}
{* *! version 1.0.0}{...}
{vieweralsosee "stpm3 postestimation" "help stpm3_postestimation"}{...}
{vieweralsosee "stpm3 extended varlist" "help stpm3_extfunctions"}{...}
{vieweralsosee "stpm3km" "help stpm3km"}{...}
{vieweralsosee "standsurv" "help standsurv"}{...}
{viewerjumpto "Syntax" "stpm3##syntax"}{...}
{viewerjumpto "Description" "stpm3##description"}{...}
{viewerjumpto "Options" "stpm3##options"}{...}
{viewerjumpto "Examples" "stpm3##examples"}{...}
{viewerjumpto "Stored results" "stpm3##results"}{...}
{title:Title}

{p2colset 5 14 16 2}{...}
{p2col:{bf:stpm3} {hline 2}} Flexible parametric survival models{p_end}
{p2colreset}{...}

{p 4 6 2}
See {bf:{browse "https://pclambert.net/software/stpm3/": "https://pclambert.net/software/stpm3/}}, 
for some examples.

{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:stpm3} [{help stpm3_extfunctions:{it:extended varlist}}] [{varlist}] {ifin}
[{cmd:,} {it:options}]

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt allknots(numlist)}}knot locations for baseline hazard{p_end}
{synopt:{opt allknotstvc(numlist)}}knot locations for time-dependent effects{p_end}
{synopt:{opt bhaz:ard(varname)}}relative survival models with backgound rates {varname}{p_end}
{synopt:{opt bknots(# #)}}location of boundary knots{p_end}
{synopt:{opt bknotstvc(# #)}}location of boundary knots for time-dependent effects{p_end}
{synopt:{opt deg:ree(#)}}degree when using B-splines{p_end}
{synopt:{opt df(#)}}degress of freedom for the baseline hazard{p_end}
{synopt:{opt dftvc(df_list)}}degrees of freedom for each time-dependent effect{p_end}
{synopt:{opt integoptsions(options)}}different options for numerical integration{p_end}
{synopt:{opt knots(numlist)}}knot locations for baseline hazard{p_end}
{synopt:{opt knotst:vc(numlist)}}knot locations for time-dependent effects{p_end}
{synopt:{opt mladoptsions(options)}}pass specifc options to {cmd:mlad}{p_end}
{synopt:{opt offset(varname)}}include offset{p_end}
{synopt:{opt nocon:stant}}suppress constant term{p_end}
{synopt:{opt python}}Use python to estimate parameters (loghazard scale models){p_end}
{synopt:{opt sc:ale(scalename)}}scale on which the survival model is
 to be fitted{p_end}
{synopt:{opt splinet:ype(splinetype)}}type of spline for modelling effect of time{p_end}
{synopt:{opt ttr:ans(function)}}transformation of time{p_end}
{synopt:{opt tvc([extended] varlist)}}variables with time-dependent effects{p_end}
{synopt:{opt tvcoffset(list)}}time offset for time-dependent effects{p_end}

{syntab:Reporting}
{synopt :{opt ef:orm}}exponentiate coefficients{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt neq(#)}}number of equations to display.{p_end}
{synopt :{opt verb:ose}}verbose output details{p_end}

{syntab:Estimation options}
{synopt:{opt initm:odel(modeltype)}}model used for initial values{p_end}
{synopt:{opt initmodelloop}}loop over different inital model types{p_end}
{synopt:{opt mlmethod(method)}}estimation method{p_end}
{synopt :{opt nod:es(#)}}number of nodes for Gauss-Legendre integration{p_end}
{synopt :{it:{help stpm3##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}




{marker description}{...}
{title:Description}

{pstd}
{cmd:stpm3} fits a a range of flexible parametric survival models using splines. 
These include models on the following scales,
log cumulative hazard, log odds, probit and log hazard.

{pstd}
{cmd:stpm3} fits similar models to {help stpm2}. In addition, {cmd:stpm3} is fully
compatible with factor variables, supports {help stpm3_extfunctions:extended functions}
and has improved {help stpm3_postestimation:postestimation} functionality.

{pstd}
With the {cmd:bhazard()} option, {cmd:stpm3} fits relative survival models.

{marker tutorials}{...}
{title:Tutorials}

{pstd}
For some tutorials and examples, see 
{bf:{browse "https://pclambert.net/software/stpm3/":https://pclambert.net/software/stpm3/}}.


{marker options}{...}
{title:Options}

{dlgtab:Model}
{phang}
{opt allknots(# [# ...])} specifies knot locations for the baseline function, 
as opposed to the default locations set by {cmd:df()}. 
This option lists all knots including boundary knots.
When specifying the knots, these are defined on the time scale by default.
When {cmd:stpm3} uses a log transformation of time, the values inputted will
be log transformed. Alternatively, the knots can be specified on the log scale using
the {cmd:lntime} suboption or as percentiles of the distribution of event times
using the {cmd:percentile}  suboption.

{phang}
{opt allknotstvc(numlist)} or {opt allknotstvc(varname # [#..#] ... varname # [#..#])}
defines the knot locatations for time-dependent effects.
This option lists all knots including boundary knots.
The first syntax uses the same knots positions for all variables listed in {cmd:tvc()}.
The second syntax allows different knot positions to be specified for each
variable included in {cmd:tvc()}.

{phang}
{opt bhazard(varname)} is used when fitting relative survival models.
{it:varname} gives the expected mortality rate (hazard) at the time of death/censoring.
{cmd:stpm3} gives an error message when there are missing values of {it:varname},
since usually this indicates an error has occurred when merging the
expected mortality rates with the time to death/censoring. 

{phang}
{opt bknots(#1 #2, [options])} specifies the locacation of the boundary knots.
By default these are placed at the minimum and maximum events times.
Note that when specifying #1 and #2 these are defined on the time scale by default.
When {cmd:stpm3} uses a log transformation of time, the values inputted will
be log transformed. Alternatively, #1 and #2 can be specified on the log scale using
the {cmd:lntime} suboption or as percentiles of the distribution of event times
using the {cmd:percentile}  suboption.

{phang}
{opt bknotstvc(#1 #2)} specifies the locacation of the boundary knots
for any variables defined in the {cmd:tvc()} option.
By default these are placed at the minimum and maximum events times.
Note it is not currently possible to define these to be different 
for different variables specified in {cmd:tvc()}.

{phang}
{opt degree(#)} (for B-splines only) gives the degree of the B-spline function.
Default is {cmd:degree(3)}.

{phang}
{opt df(#)} specifies the degrees of freedom for the spline function used
for the baseline function. 
When using {opt df(#)}, knots are placed at evenly spread centiles of the
distribution of the uncensored log event times. 
The number of internal knots will be {it:#} - 1.
With 1 degree of freedom,
no knots are involved and a linear or log-linear effect of time is imposed.

{phang}
{opt dftvc(#)} or  {opt dftvc(varname # ... varname #)} gives the degrees of freedom 
for time-dependent effects.
If using the first syntax, {opt dftvc(#)}, then the save degrees of fredom
are used for any covariates listed in the {cmd:tvc()} option.
If using the second syntax, separate degrees of freedon can be listed for
each covriate listed in the {cmd:tvc()} option.

{phang}
{opt knots(# [# ...])} specifies internal knot locations for the baseline function, 
as opposed to the default locations set by {cmd:df()}. 
When specifying the knots, these are defined on the time scale by default.
When {cmd:stpm3} uses a log transformation of time, the values inputted will
be log transformed. Alternatively, the knots can be specified on the log scale using
the {cmd:lntime} suboption or as percentiles of the distribution of event times
using the {cmd:percentile}  suboption.

{phang}
{opt knotstvc(numlist)} or {opt knotstvc(varname # [#..#] ... varname # [#..#])}
defines the internal knot locatations for time-dependent effects.
The first syntax uses the same knots positions for all variables listed in {cmd:tvc()}.
The second syntax allows different knot positions to be specified for each
variable included in {cmd:tvc()}.

{phang}
{opt integoptions(options)} This controls numerical integration options when fitting
models on the log hazard scale. 
When the spline functions are a function of log time the default method is
{cmd:tanhsinh} quadrature and when the spline functions are a function of 
untransformed time Gauss-Legendre ({cmd:gl}) quadrature is the default.
Three part integration is the default for both tanh-sinh quadrature and
Gauss-Legendre quadrature, where analytical derivatives 
are used before the lowest knot and after the highest knot, with numerical 
integration used between the lowest and highest knots. 
This can be overridden with the {cmd:allnum} option, where numerical integration
is used over the whole time scale. 

{phang}
{opt mladoptions(options)} Pass various options to {cmd:mlad} (see {help mlad}). This was mainly
used when developing the {cmd:python} option, so will not be relevant for
most users.

{phang}
{opt offset(varname)} This is not currently implemented and will result in an error. 

{phang}
{opt noconstant} excludes the constant from the model.

{phang}
{opt python} will use Python to to do some of the more computationally intensive 
methods for models on the loghazard scale. To use this option, you need to have
installed the {cmd:mlad} command from SSC as well as have installed Python
and some specific Python modules. See  {browse "https://pclambert.net/software/mlad/":https://pclambert.net/software/mlad/}
for more details.

{phang}
{opt scale(scalename)} specifies the scale on which the survival model is to be
fitted. 

{pmore}
{cmd:scale(lncumhazard|logcumhazard)} or {cmd:scale(logcumhazard)} fit a model on the log cumulative hazard scale, 															 
i.e. ln(-ln S(t)), where S(t) is the
survival function. 
If no time-dependent effects are specified,
the model has proportional hazards.
With 1 df this is equivalent to a Weibull model.

{pmore}
{cmd:scale(lnhazard|loghazard)} or {cmd:scale(loghazard)} fit a model on the log hazard scale,
i.e. ln[h(t)]. If no time-dependent effects are specified,
the model has proportional hazards.

{pmore}
{cmd:scale(lnodds)} or {cmd:scale(logodds)} fit a model on the log cumulative odds scale,
i.e. ln((1 - S(t))/S(t)). If no time-dependent effects 
are specified the model has proportional odds.
With 1 df this is equivalent to a loglogistic model.

{pmore}
{cmd:scale(probit)} or {cmd:scale(probit)} fit a model on the 
with a probit link function for the survival function, invnorm(1 - S(t))).
With 1 df this is equivalent to a lognormal model.

{phang}
{opt splinetype(splinetype)} defines the type of spline used to model the effect of time. 

{pmore}
{cmd:splinetype(ns)} specifies natural cubic splines. This is the default.

{pmore}
{cmd:splinetype(bs)} specifies B-splines. The {cmd:degree()} option specifies the degree of the B-spline.

{pmore}
{cmd:splinetype(rcs)} specified restricted cubic splines, which give the same predicted values as {cmd:splinetype(ns)}. Since the spline basis functions are calculated in different ways the associated coefficents will differ.

{phang}
{opt ttrans(function)} defines the function of time used as an argument for the spline function. The default {it:function} is {bf:log}. {cmd:ttrans(none)}
uses untransformed time.

{phang}
{opt tvc(varlist)} gives the names of the variables whose effects are
to be modelled as time-dependent. 																	  
Time-dependent effects are fitted using the same spline function type as the baseline.
The degrees of freedom are determined by {opt dftvc()}. 

{phang}
{opt tvcoffset(list)} is not currently implemented. 

{dlgtab:Reporting}

{phang}
{opt eform} displays the exponentiated coefficients and corresponding standard errors 
and confidence intervals for {cmd:xb} equation.

{phang}
{opt le:vel(#)} see
{helpb estimation options##level():[R] Estimation options}.

{phang}
{opt neq(#)} number of equations to display. 
In a model with covariates {cmd:neq(1)} omits the coefficients associated with 
the spline parameters and {cmd:neq(0)} omits all coeficients and just 
displays summary information.

{phang}
{opt verbose} gives some details about the progress in the setup/estimation process.
This was useful when developing/debugging the command.

{dlgtab:Maximization/Estimation}

{phang}
{opt initmodel(modeltype)} defines the model used to obtain initial values.
Options are {cmd:cox} (default), {cmd:weibull}, {cmd:exp} and {cmd:stpm2}.

{phang}
{opt initvaluesloop} searches for initial values over several {it:modeltype}s.

{phang}see {helpb maximize:[R] Maximize} for other maximization options.


{marker examples}{...}
{dlgtab:Examples}

{phang}
These are very simple examples.  For more complex examples see 
{bf:{browse "https://pclambert.net/software/stpm3/":https://pclambert.net/software/stpm3/}}.

{phang}
You can click on the commands below to run the commands, but will need to
clear data from memory before using {cmd:webuse}

{pstd}Load data and set time-scale to years (days/365.24){p_end}
{phang2}{stata "webuse brcancer"}{p_end}
{phang2}{stata "stset rectime, failure(censrec = 1) scale(365.24)"}{p_end}

{phang}
{ul:{bf:Example 1: Proportional hazards model on log cumulative hazard scale}}
{p_end}

{phang2}{stata "stpm3 i.hormon, scale(lncumhazard) df(4) eform"}{p_end}

{phang}
{ul:{bf:Example 2: Proportional hazards model on log hazard scale}}
{p_end}

{phang2}{stata "stpm3 i.hormon, scale(lnhazard) df(4) eform"}{p_end}

{phang}
{ul:{bf:Example 3: Proportional odds model}}
{p_end}

{phang2}{stata "stpm3 i.hormon, scale(lnodds) df(4) eform"}{p_end}

{phang}
{ul:{bf:Example 4: log hazard model using quadratic B-splines}}
{p_end}

{phang2}{stata "stpm3 i.hormon, scale(lnhazard) df(4) splinetype(bs) degree(2) eform"}{p_end}

{phang}
{ul:{bf:Example 5: log hazard model using natural splines with interaction with time}}
{p_end}

{phang2}{stata "stpm3 i.hormon, scale(lnhazard) df(4) tvc(i.hormon) dftvc(3)"}{p_end}


{title:Author}

{p 5 12 2}{bf:Paul C. Lambert}{p_end}        
{p 5 12 2}Biostatistics Research Group{p_end}
{p 5 12 2}Department of Population Health Sciences{p_end}
{p 5 12 2}University of Leicester{p_end}
{p 5 12 2}Leicester, UK{p_end}
{p 5 12 2}{it: and}{p_end}
{p 5 12 2}Department of Medical Epidemiology and Biostatistics{p_end}
{p 5 12 2}Karolinska Institutet{p_end}
{p 5 12 2}Stockholm, Sweden{p_end}
{p 5 12 2}paul.lambert@le.ac.uk{p_end}


{title:References}

{phang}
{bf:P. C. Lambert and P. Royston}. Further development of flexible parametric
models for survival analysis. {browse "https://journals.sagepub.com/doi/10.1177/1536867X0900900206:":{it:Stata Journal} 2009;9:265-290}

{phang}
{bf:C. P. Nelson, P. C. Lambert, I. B. Squire and D. R. Jones.} 
Flexible parametric models for relative survival, with application
in coronary heart disease. Statistics in Medicine 2007;26:5486-5498

{phang}
{bf:P. Royston and M. K. B. Parmar}. Flexible proportional-hazards and
proportional-odds models for censored survival data, with application
to prognostic modelling and estimation of treatment effects.
Statistics in Medicine 2002;21:2175-2197.

{phang}
{bf:P. Royston, P.C. Lambert}. {browse `"https://www.stata.com/bookstore/flexible-parametric-survival-analysis-stata"':Flexible parametric survival analysis in Stata: Beyond the Cox model}. StataPress, 2011




