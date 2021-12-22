{smcl}
{* *! version 1.0.0  ?????2018}{...}
{vieweralsosee "merlin" "help merlin"}{...}
{viewerjumpto "Syntax" "merlin_postestimation##syntax"}{...}
{viewerjumpto "Description" "merlin_postestimation##description"}{...}
{viewerjumpto "Options" "merlin_postestimation##options"}{...}
{viewerjumpto "Remarks" "merlin_postestimation##remarks"}{...}
{viewerjumpto "Examples" "merlin_postestimation##examples"}{...}

{marker syntax}{...}
{title:Syntax for predict}

{pstd}
Syntax for predictions following a {helpb merlin:merlin} model

{p 8 16 2}
{cmd:predict}
{it:newvarname}
{ifin} [{cmd:,}
{it:{help merlin_postestimation##statistic:statistic}}
{it:{help merlin_postestimation##opts_table:options}}]

{phang}
The default is to make predictions based only on the fixed portion of the 
model.  

{p 4 4 2}
Syntax for obtaining estimated latent variables and their standard errors

{p 8 16 2}
{cmd:predict} 
{it:newvarsspec}
{ifin}
{cmd:,}
[{opt ref:fects} {opt reses}]

{p 8 16 2}
where {it:newvarsspec} is {it:stub}{cmd:*} or {it:{help newvarlist}}.


{marker statistic}{...}
{synoptset 25 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{syntab:Main}
{synopt :{opt mu}}expected value of {depvar}; the default{p_end}
{synopt :{opt eta}}expected value of complex predictor{p_end}
{synopt :{opt surv:ival}}survivor function{p_end}
{synopt :{opt totalsurv:ival}}all-cause survivor function{p_end}
{synopt :{opt cif}}cumulative incidence function{p_end}
{synopt :{opt h:azard}}hazard function{p_end}
{synopt :{opt ch:azard}}cumulative hazard function{p_end}
{synopt :{opt logch:azard}}log cumulative hazard function{p_end}
{synopt :{opt rmst}}restricted mean survival time, within (0,{it:t}]{p_end}
{synopt :{opt timel:ost}}time lost due to an event, within (0,{it:t}]{p_end}
{synopt :{opt totaltimel:ost}}total time lost due to all events, within (0,{it:t}]{p_end}
{synopt :{opt userf:unction(func_name)}}user-defined Mata function{p_end}
{synopt :{opt mudiff:erence}}difference in expected values of {depvar}{p_end}
{synopt :{opt etadiff:erence}}difference in expected value of complex predictor{p_end}
{synopt :{opt hdiff:erence}}difference in hazard functions{p_end}
{synopt :{opt sdiff:erence}}difference in survival functions{p_end}
{synopt :{opt cifdiff:erence}}difference in cumulative incidence functions{p_end}
{synopt :{opt rmstdiff:erence}}difference in restricted mean survival functions{p_end}
{synopt :{opt mur:atio}}ratio of expected values of {depvar}{p_end}
{synopt :{opt etar:atio}}ratio of expected value of complex predictor{p_end}
{synopt :{opt hr:atio}}ratio of hazard functions{p_end}
{synopt :{opt sr:atio}}ratio of survival functions{p_end}
{synopt :{opt cifr:atio}}ratio of cumulative incidence functions{p_end}
{synopt :{opt rmstr:atio}}ratio of restricted mean survival functions{p_end}
{synopt :{opt ref:fects}}empirical Bayes means of latent variables{p_end}
{synopt :{opt reses}}standard errors of empirical Bayes estimates{p_end}
{synoptline}

{marker opts_table}{...}
{synoptset 25 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Main}
{synopt :{opt fixedonly}}compute {it:statistic} based only on the fixed portion of the model; the default{p_end}
{synopt :{opt marginal}}compute {it:statistic} marginally with respect to the latent variables{p_end}
{synopt :{opt stand:ardise}}compute {it:statistic} marginally with respect to the independent variables{p_end}
{synopt :{cmd:outcome(}{it:#}{cmd:)}}specify observed response variable (default 1){p_end}
{synopt :{opth causes(numlist)}}specify which {cmd:merlin} submodels contribute to the {it:statistic}{p_end}
{synopt :{opt at(at_spec)}}specify covariate values for prediction{p_end}
{synopt :{opt zero:s}}set all covariates to zero{p_end}
{synopt :{opt at1(at_spec)}}specify covariate values for prediction; for use with difference and ratio predictions{p_end}
{synopt :{opt at2(at_spec)}}specify covariate values for prediction; for use with difference and ratio predictions{p_end}
{synopt :{opt ci}}calculate confidence intervals{p_end}
{synopt :{opt reps(#)}}number of bootstrap samples for {cmd:ci}s; see details{p_end}
{synopt :{cmd:timevar(}{varname}{cmd:)}}calculate predictions at specified time-points{p_end}
{synopt :{opth ltrunc:ated(varname)}}calculate conditional predictions{p_end}

{syntab :Integration}
{synopt :{opt intp:oints(#)}}use {it:#} integration points to compute marginal predictions{p_end}
{synopt :{opt chintp:oints(#)}}use {it:#} integration points when computing cumulative hazard functions{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:predict} is a standard postestimation command of Stata.
This entry concerns use of {cmd:predict} after {cmd:merlin}.

{pstd}
{cmd:predict} after {cmd:merlin} creates new variables containing
observation-by-observation values of estimated observed response variables,
linear predictions of observed response variables, or other such functions.


{marker options}{...}
{title:Options}

{dlgtab:Statistic}

{phang}
{cmd:mu}, the default, calculates the expected value of the outcomes.

{phang} 
{cmd:eta} calculates the fitted linear prediction.

{phang} 
{cmd:survival} calculates the survival function. If you have fitted a competing risks model, then this will represent 
cause-specific survival.

{phang} 
{cmd:totalsurvival} calculates the all-cause survival function at time {it:t}, where {it:t} is the time at which predictions are made. 
In a single event survival model, this is the same as {cmd:survival}. 
In a competing risks {cmd:merlin} model, all survival models in the fitted {cmd:merlin} model are assumed to 
be cause-specific event time models contributing to the calculation. If this is not the case, you can tell {cmd:predict} which 
of the models are cause-specific hazard models by using the {cmd:causes()} option. 

{phang} 
{cmd:cif} calculates the cumulative incidence function at time {it:t}, where {it:t} is the time at which predictions are made. 
In a single event survival model, this is 1 - survival. 
In a competing risks {cmd:merlin} model, all survival models in the fitted {cmd:merlin} model are assumed to 
be cause-specific event time models contributing to the calculation. If this is not the case, you can tell {cmd:predict} which 
of the models are cause-specific hazard models by using the {cmd:causes()} option. 

{phang} 
{cmd:hazard} calculates the hazard function at time {it:t}, where {it:t} is the time at which predictions are made. 

{phang}
{cmd:chazard} calculates the cumulative hazard function at time {it:t}, where {it:t} is the time at which predictions are made. 

{phang}
{cmd:logchazard} calculates the log of the cumulative hazard function at time {it:t}, where {it:t} is the time at which predictions are made. 

{phang} 
{cmd:rmst} calculates the restricted mean survival time, which is the integral of the survival function within the interval 
(0,{it:t}], where {it:t} is the time at which predictions are made. If multiple survival 
models have been specified in your {cmd:merlin} model, then it will assume all of them are cause-specific competing risks models, 
and include them in the calculation. If this is not the case, you can override which models are included by using the {cmd:causes()} 
option. {cmd:rmst} = {it:t} - {cmd:totaltimelost}.

{phang} 
{cmd:timelost} calculates the time lost due to a particular event occuring, within the interval (0,{it:t}]. 
In a single event survival model, this is the integral of the {cmd:cif} between (0,{it:t}].
If multple survival models are specified in the {cmd:merlin} model then by default all are assumed to be cause-specific 
event time models contributing to the calculation. This can be overridden using the {cmd:causes()} option.

{phang} 
{cmd:totaltimelost} calculates the total time lost due to any event occuring, within the interval (0,{it:t}]. 
In a single event survival model, this is the integral of the {cmd:cif} between (0,{it:t}], and will be equivalent 
to {cmd:timelost}. If multiple survival models are specified in the {cmd:merlin} model then by default all are 
assumed to be cause-specific event time models contributing to the calculation. This can be overridden using 
the {cmd:causes()} option. {cmd:totaltimelost} is the sum of the {cmd:timelost} due to all causes.

{phang} 
{cmd:userfunction(}{it:func_name}{cmd:)} calculates a user-defined prediction, based on a Mata function passed to {cmd:predict}. See 
{helpb merlin user:merlin user-defined functions} for more info.

{phang} 
{cmd:mudifference} calculates the difference in the expected value of the outcomes, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:etadifference} calculates the difference in the expected value of the complex predictor, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:hdifference} calculates the difference in hazard function at time {it:t}, where {it:t} is the time at which predictions are made, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:sdifference} calculates the difference in survival function at time {it:t}, where {it:t} is the time at which predictions are made, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:cifdifference} calculates the difference in cumulative incidence function at time {it:t}, where {it:t} is the time at which predictions are made, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:rmstdifference} calculates the difference in restricted mean survival time at time {it:t}, where {it:t} is the time at which predictions are made, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:muratio} calculates the ratio of the expected value of the outcomes, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:etaratio} calculates the ratio of the expected value of the complex predictor, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:hratio} calculates the ratio of hazard functions at time {it:t}, where {it:t} is the time at which predictions are made, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:sratio} calculates the ratio of survival functions at time {it:t}, where {it:t} is the time at which predictions are made, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:cifratio} calculates the ratio of cumulative incidence functions at time {it:t}, where {it:t} is the time at which predictions are made, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{phang} 
{cmd:rmstratio} calculates the ratio of restricted mean survival times at time {it:t}, where {it:t} is the time at which predictions are made, 
across the covariate patterns specified in {cmd:at1()} and {cmd:at2()}. 

{marker reffects}{...}
{phang}
{opt reffects} calculates empirical Bayes estimates (posterior means) of the 
random effects. You must specify q new variables, where q is the number of random-effects terms
in the model (or level). However, it is much easier to just specify 
{it:stub}{cmd:*} and let Stata name the variables {it:stub}{cmd:1},
{it:stub}{cmd:2}, ..., {it:stub}q for you.

{phang}
{opt reses}
calculates the standard errors of the empirical Bayes etsimates of the random effects. You must specify q new variables, 
where q is the number of random-effects terms in the model (or level).  However, it is much easier to
just specify {it:stub}{cmd:*} and let Stata name the variables
{it:stub}{cmd:1}, {it:stub}{cmd:2}, ..., {it:stub}q for you.

{pmore}
The {cmd:reffects} and {cmd:reses} options often generate multiple new 
variables at once.  When this occurs, the random effects (or standard 
errors) contained in the generated variables correspond to the order in which
the variance components are listed in the output of {cmd:merlin}.


{dlgtab:Options}

{phang}
{cmd:causes(numlist)} is for use when calculating predictions from a competing risks {cmd:merlin} model. By default, 
{cmd:cif}, {cmd:rmst}, {cmd:timelost} and {cmd:totaltimelost} assume that all survival models included in the {cmd:merlin} 
model are cause-specific hazard models contributing to the calculation. If this is not the case, then you can specify which 
models (indexed using the order they appear in your {cmd:merlin} model, e.g. {cmd:causes(1 2)}), by using the {cmd:causes()} 
option.

{phang}
{cmd:fixedonly} specifies that the predicted {it:statistic} be computed
based only on the fixed portion of the model. This is the default.

{phang}
{cmd:marginal} specifies that the predicted {it:statistic} be computed
marginally with respect to the latent variables.

{phang2}
Although this is not the default, marginal predictions are often very useful
in applied analysis.  They produce what are commonly called
population-averaged estimates. 

{phang2}
For models with continuous latent variables, the {it:statistic} is calculated
by integrating the prediction function with respect to all the latent
variables over their entire support.

{phang}
{cmd:standardise} specifies that the predicted {it:statistic} be computed
marginally with respect to the independent variables. This is implemented by calculating the {it:statistic} 
at all observed covariate patterns, and taking the average. Can be used in combination with {cmd:at()}, or {cmd:at1()} and 
{cmd:at2()} to obtain causal estimands/contrasts.

{phang}
{cmd:outcome(}{it:#}{cmd:)} specifies that predictions for
outcome {it:#} be calculated.

{phang}
{opt at(varname # [ varname # ...])} requests that the covariates specified by 
the listed {it:varname}(s) be set to the listed {it:#} values. For example,
{cmd:at(trt 1 age 50)} would evaluate predictions at {cmd:trt} = 1 and
{cmd:age} = 50. This is a useful way to obtain out of sample predictions. Other covariates in your model, but 
{bf:not} included in {cmd:at()} will be set to their observed values, i.e. the values in your dataset. Note that if {cmd:at()} 
is used together with {cmd:zeros}, all covariates not listed in {cmd:at()} are set to zero. See also {cmd:zeros}.

{phang}
{opt zeros} sets all covariates to zero. See also {cmd:at()}. Note, any response variables will be skipped, i.e. not set 
to zero, so if a response variable for one model is included as a covariate in another - it will {it:not} be set to zero. Also note 
that it {cmd:at1()} and {cmd:at2()} are specified, then {cmd:zeros} applies to both.

{phang}
{opt at1(varname # [ varname # ...])} does the same as {cmd:at()} but for use in conjunction with {cmd:?difference} or 
{cmd:?ratio} predictions.

{phang}
{opt at2(varname # [ varname # ...])} does the same as {cmd:at()} but for use in conjunction with {cmd:?difference} or 
{cmd:?ratio} predictions.

{phang}
{cmd:ci} specifies that confidence intervals are calculated for the predicted {it:statistic}. The multivariate delta 
method (i.e. {cmd:predictnl}) is used for all calculations, except when a {cmd:family(cox)} model has been fitted, 
in which case boostrapping is used. The calculated confidence intervals are generated in {it:newvarname_lci} 
and {it:newvarname_uci}.

{phang}
{cmd:reps(#)} specifies the number of bootstrap samples to use when calculating confidence intervals for a prediction 
from a {cmd:family(cox)} model. Default is {cmd:reps(100)}.

{phang}
{cmd:timevar(}{varname}{cmd:)} calculate predictions at specified time-points. 
For survival models, the default is to calculate predictions at the evemt/censoring times. 
For a {cmd:merlin} model where a {cmd:timevar()} was specified, then the default will use the original 
{cmd:timevar()}. This option overides it.{p_end}

{phang}
{opth ltruncated(varname)} calculates left-truncated, conditional predictions, e.g., {it:S(t|t0)}, where t0 is defined by the times in 
{cmd:ltruncated()}. Only allowed with {cmd:survival} or {cmd:cif}.
{p_end}

{dlgtab:Integration}

{phang}
{opt intpoints(#)} specifies the number of integration points used to
compute marginal predictions; the default is the value from estimation.

{phang}
{opt chintpoints(#)} defines the number of Gauss-Legendre integreation (quadrature) points used to calculate analytically intractable 
cumulative hazard functions; the default is the value from estimation.


{marker remarks}{...}
{title:Remarks}

{pstd}
Out-of-sample prediction is allowed for all {cmd:predict} options.


{marker examples}{...}
{title:Example 1}

{pstd}Setup{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/s/stjm_pbc_example_data, clear}{p_end}

{pstd}Linear mixed effects model with {cmd:merlin}{p_end}
{phang2}{cmd:. merlin (logb time age trt time#M1[id]@1 M2[id]@1, family(gaussian))}{p_end}

{pstd}Predict the expected value of {cmd:logb} marginalised over the random effects{p_end}
{phang2}{cmd:. predict ev1, eta marginal}{p_end}

{title:Example 2}

{phang}Fit a Royston-Parmar flexible parametric model:{p_end}
{phang2}{cmd:. webuse brcancer,clear}{p_end}
{phang2}{cmd:. stset rectime, failure(censrec) scale(365)}{p_end}
{phang2}{cmd:. merlin (_t hormon, family(rp, df(3) failure(_d)))}{p_end}

{phang}Predict the survival function{p_end}
{phang2}{cmd:. predict s1, survival}{p_end}

{phang}Predict the conditonal survival function at user-defined times{p_end}
{phang2}{cmd:. range tvar 5 10 100}{p_end}
{phang2}{cmd:. gen t0 = 5}{p_end}
{phang2}{cmd:. predict s2, survival timevar(tvar) ltruncated(t0)}{p_end}


{title:Author}

{p 5 12 2}
{bf:Michael J. Crowther}{p_end}
{p 5 12 2}
Red Door Analytics{p_end}
{p 5 12 2}
Stockholm, Sweden{p_end}
{p 5 12 2}
michael@reddooranalytics.se{p_end}


{title:References}

{phang}
{bf:Crowther MJ}. Extended multivariate generalised linear and non-linear mixed effects models. 
{browse "https://arxiv.org/abs/1710.02223":https://arxiv.org/abs/1710.02223}
{p_end}

{phang}
{bf:Crowther MJ}. merlin - a unified framework for data analysis and methods development in Stata. {browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X20976311":{it:Stata Journal} 2020;20(4):763-784}.
{p_end}

{phang}
{bf:Crowther MJ}. Multilevel mixed effects parametric survival analysis: Estimation, simulation and application. {browse "https://journals.sagepub.com/doi/abs/10.1177/1536867X19893639?journalCode=stja":{it:Stata Journal} 2019;19(4):931-949}.
{p_end}

{phang}
{bf:Crowther MJ}, Lambert PC. Parametric multi-state survival models: flexible modelling allowing transition-specific distributions with 
application to estimating clinically useful measures of effect differences. {browse "https://onlinelibrary.wiley.com/doi/full/10.1002/sim.7448":{it: Statistics in Medicine} 2017;36(29):4719-4742.}
{p_end}

{phang}
Weibull CE, Lambert PC, Eloranta S, Andersson TM-L, Dickman PW, {bf:Crowther MJ}. A multi-state model incorporating 
estimation of excess hazards and multiple time scales. {browse "https://onlinelibrary.wiley.com/doi/10.1002/sim.8894":{it:Statistics in Medicine} 2021; (In Press)}.
{pstd}
