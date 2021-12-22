{smcl}
{* *! version 0.1.0  ?????2017}{...}
{vieweralsosee "stmerlin postestimation" "help stmerlin_postestimation"}{...}
{vieweralsosee "merlin" "help merlin"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{helpb stmerlin} {hline 2}}convenience wrapper for estimating a parametric and semi-parametric survival model with 
{helpb merlin}, optionally including multiple timescales{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:stmerlin} [{it:{help merlin_models:indepsyntax}}] {ifin} , {cmd:distribution(}{it:model}{cmd:)} 
	[, {help stmerlin##options:{it:options}} 
	{help stmerlin##displayopts:{it:display_options}}]

{phang2}where {it:{help merlin_models:indepsyntax}} is a {helpb merlin} linear predictor, which can be anything from 
a simple {varlist}, to directly specifying spline or fractional polynomial functions of continuous covariates.
	
{phang2}You must {cmd:stset} your data before using {cmd:stmerlin}; see {manhelp stset ST}.{p_end}


{synoptset 27}{...}
{marker options}{...}
{synopthdr:options}
{synoptline}
{synopt :{opt d:istribution}{cmd:(}{opt addrcs)}}hazard scale spline model{p_end}
{synopt :{opt d:istribution}{cmd:(}{opt e:xponential)}}exponential model{p_end}
{synopt :{opt d:istribution}{cmd:(}{opt cox)}}Cox model{p_end}
{synopt :{opt d:istribution}{cmd:(}{opt go:mpertz)}}Gompertz model{p_end}
{synopt :{opt d:istribution}{cmd:(}{opt gg:amma)}}generalised gamma{p_end}
{synopt :{opt d:istribution}{cmd:(}{opt logn:ormal)}}log normal{p_end}
{synopt :{opt d:istribution}{cmd:(}{opt logl:ogistic)}}log logistic{p_end}
{synopt :{opt d:istribution}{cmd:(}{opt pwe:xponential)}}piecewise-exponential model{p_end}
{synopt :{opt d:istribution}{cmd:(}{opt rp)}}Royston-Parmar model{p_end}
{synopt :{opt d:istribution}{cmd:(}{opt rcs)}}Log-hazard scale spline model{p_end}
{synopt :{opt d:istribution}{cmd:(}{opt w:eibull)}}Weibull model{p_end}
{synopt :{opt nocons:tant}}omit the constant term{p_end}
{synopt :{opth df(#)}}degrees of freedom for the baseline function with {cmd:rp} or {cmd:rcs} models; see details{p_end}
{synopt :{opt knots(knots_list)}}knot locations for the baseline function with {cmd:rp} or {cmd:rcs} models; see details{p_end}
{synopt :{opth tvc(varlist)}}time-dependent effects{p_end}
{synopt :{opth dftvc(numlist)}}degrees of freedom for each time-dependent effect{p_end}
{synopt :{opt tvctime}}use splines of time rather than log time for time-dependent effects{p_end}
{synopt :{opt noorth:og}}turns off the default orthogonalisation of any spline terms{p_end}
{synopt :{opth bh:azard(varname)}}expected event rate at event times, invokes a relative survival model{p_end}
{synopt:{bf:time#(}{help stmerlin##mt_opts:{it:mt_opts}})}define two to five additional timescales modelled with restricted cubic 
splines, specified with {cmd:time2({help stmerlin##mt_opts:{it:mt_opts}})}, 
with a maximum of {cmd:time5({help stmerlin##mt_opts:{it:mt_opts}})}{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 27}{...}
{marker mt_opts}{...}
{synopthdr:multiple timescale options}
{synoptline}
{synopt :{opth offset(varname)}}defines the offset to be added to {cmd:_t} to define the additional timescale{p_end}
{synopt :{opth moffset(varname)}}defines the offset to be taken away ("minused") from {cmd:_t} to define the additional timescale{p_end}
{synopt :{opth df(#)}}degrees of freedom for timescale spline function{p_end}
{synopt :{opt knots(knots_list)}}knot locations for the timescale spline function{p_end}
{synopt :{opth tvc(varlist)}}time-dependent effects on the additional timescale{p_end}
{synopt :{opth dftvc(numlist)}}degrees of freedom for each time-dependent effect{p_end}
{synopt :{opt tvctime}}use splines of time rather than log time for time-dependent effects{p_end}
{synopt :{opt noorth:og}}turns off the default orthogonalisation of any spline terms{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 27}{...}
{marker displayopts}{...}
{synopthdr:display options}
{synoptline}
{synopt :{opt showmerlin}}display the underlying {helpb merlin} model syntax{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:stmerlin} fits survival models, including a range of parametric distributions, flexible spline-based models, and the 
Cox model, possibly including multiple timescales. It is a convenience wrapper of the more powerful {helpb merlin} command, 
but with a much more user-friendly syntax. Time-dependent effects can be specified using restricted cubic splines through options, 
or in alternative ways using {helpb merlin}'s linear predictor syntax. For predictions available post-estimation, see 
{helpb stmerlin postestimation}.
{p_end}

{pstd}
The {helpb merlin} command fits an extremely broad class of mixed effects regression models for linear, non-linear and 
user-defined outcomes. For full details and many tutorials, take a look at the accompanying website: 
{browse "https://www.mjcrowther.co.uk/software/merlin":mjcrowther.co.uk/software/merlin}
{p_end}


{marker options}{...}
{title:Options}

{phang}{opt distribution(model)} specifies the distributional family. They include: 

{phang2}{cmd: distribution(addrcs)} fits a spline-based flexible parametric survival model, using restricted cubic splines of 
log time, to model the baseline hazard function.

{phang2}{cmd: distribution(exponential)} fits an exponential model.

{phang2}{cmd: distribution(cox)} fits a Cox model using maximum partial likelihood, assuming the Breslow method for 
handling ties.

{phang2}{cmd: distribution(gompertz)} fits a Gompertz model.

{phang2}{cmd: distribution(ggamma)} fits a generalised gamma accelerated failure time model.

{phang2}{cmd: distribution(lognormal)} fits a log normal accelerated failure time model.

{phang2}{cmd: distribution(loglogistic)} fits a log logistic accelerated failure time model.

{phang2}{cmd: distribution(pwexponential)} fits a piecewise-exponential model; requires the {cmd:knots()} option.

{phang2}{cmd: distribution(rp)} fits a Royston-Parmar flexible parametric survival model, using restricted cubic splines of 
log time, to model the log baseline cumulative hazard function.

{phang2}{cmd: distribution(rcs)} fits a spline-based flexible parametric survival model, using restricted cubic splines of 
log time, to model the log baseline hazard function.

{phang2}{cmd: distribution(weibull)} fits a Weibull model, in a hazards metric.

{phang}{opt noconstant} suppresses the constant (intercept) term in the linear predictor.

{phang}{opt df(#)} degrees of freedom for the baseline log [cumulative] hazard function, i.e. number of restricted cubic 
spline terms when using {cmd:distribution(rp)} or {cmd:distribution(rcs)}. Internal knots are placed at centiles of the 
event times. Boundary knots are placed at the minimum and maximum event times.

{phang}{opt knots(knots_list)} either:

{phang2}defines the knot locations for the spline functions used to model the baseline 
log [cumulative] hazard function when using {cmd:distribution(rp)} or {cmd:distribution(rcs)}. Must include boundary 
knots. Knots should be specified in increasing order.

{phang2}defines the knot locations (cut-points) the baseline function for {cmd:distribution(pwexponential)}. Knots should 
be specified in increasing order.

{phang}{opt tvc(varlist)} specifies the variables that have time-dependent effects. Time-dependent effects are fitted 
using restricted cubic splines of time or log time (the default). The degrees of freedom are specified using the 
{cmd:dftvc()} option. Note, {cmd:tvc()}s are not supported with generalised gamma, log normal or log logistic models.

{phang}{opt dftvc(numlist)} degrees of freedom for the time-dependent effects specified in {cmd:tvc()}. If only one number is 
specified, then the same degrees of freedom are applied to all {cmd:tvc()}s, otherwise, a number must be specified for each.

{phang}{opt tvctime} specified that restricted cubic splines of time are used to model time-dependent effects, rather than 
the default of log time.

{phang}{opt noorthog} suppresses orthogonal transformation of spline variables.

{phang}{opth bhazard(varname)} invokes a relative survival (excess hazard) model, by specifying the expected event rate in the reference 
population at the observed event times.

{marker multitime_details}{...}
{dlgtab:Multiple timescales}

{phang}
{opt offset(varname)} defines the offset to be added to {cmd:_t} to define the additional timescale. If time since diagnosis 
was the main timescale, and you wish to add attained age as a second timescale, the {cmd:offset()} would contain age at diagnosis.

{phang}
{opt moffset(varname)} defines the offset to be taken away ("minused") from {cmd:_t} to define the additional timescale, i.e. to 
reset the clock.

{phang}{opt df(#)} degrees of freedom for the additional timescale function, i.e. number of restricted cubic 
spline terms. Internal knots are placed at centiles of the event times. Boundary knots are placed at the minimum and maximum event times.

{phang}{opt knots(knots_list)} defines the knot locations for the spline functions used to model the additional timescale. Must include 
boundary knots. Knots should be specified in increasing order.

{phang}{opt tvc(varlist)} specifies the variables that have time-dependent effects on the additional timescale. Time-dependent effects 
are fitted using restricted cubic splines of time or log time (the default). The degrees of freedom are specified using the 
{cmd:dftvc()} option. Note, {cmd:tvc()}s are not supported with generalised gamma, log normal or log logistic models.

{phang}{opt dftvc(numlist)} degrees of freedom for the time-dependent effects specified in {cmd:tvc()}. If only one number is 
specified, then the same degrees of freedom are applied to all {cmd:tvc()}s, otherwise, a number must be specified for each.

{phang}{opt tvctime} specified that restricted cubic splines of time are used to model time-dependent effects on the additional timescale, 
rather than the default of log time.

{phang}{opt noorthog} suppresses orthogonal transformation of spline variables (additional timescale and any time-dependent effects).

{marker display_details}{...}
{dlgtab:Display}

{phang}{opt showmerlin} displays the full {helpb merlin} model syntax.


{title:Examples}

{phang}Fit a Royston-Parmar flexible parametric model:{p_end}
{cmd:    . webuse brcancer,clear}
{cmd:    . stset rectime, failure(censrec) scale(365)}
{cmd:    . stmerlin hormon, distribution(rp) df(3)}

{phang}Fit a Cox proportional hazards model:{p_end}
{cmd:    . stmerlin hormon, distribution(cox)}

{phang}Fit a Cox model with a time-dependent effect using splines:{p_end}
{cmd:    . stmerlin hormon, distribution(cox) tvc(hormon) dftvc(3)}

{phang}Fit a Cox proportional hazards model with a non-linear effect of age:{p_end}
{cmd:    . stmerlin hormon rcs(age, df(3)), distribution(cox)}


{title:Author}

{p 5 12 2}
{bf:Michael J. Crowther}{p_end}
{p 5 12 2}
Department of Medical Epidemiology and Biostatistics{p_end}
{p 5 12 2}
Karolinska Institutet{p_end}
{p 5 12 2}
Stockholm, Sweden{p_end}
{p 5 12 2}
michael.crowther@ki.se{p_end}
